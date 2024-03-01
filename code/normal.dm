
var/output_folder = "[DM_VERSION]/output"


/// Essentially a struct to hold the render data.
/datum/render_data
	/// Diffuse icon for the render.
	var/icon/diffuse_map

	/// Normal icon for the render.
	var/icon/normal_map

	/// Light direction icon for the render.
	var/icon/light_map

/datum/render_data/stairs
	diffuse_map = icon('icons/stairs.dmi', "diffuse")
	normal_map  = icon('icons/stairs.dmi', "normal")
	light_map   = icon('icons/stairs.dmi', "")


/client/verb/Render()

	/// Our render data is stored in a datum, so we can just call its render verb.
	var/datum/render_data/render_data = new /datum/render_data/stairs

	if(fexists("output/ico.dmi"))
		src << "Deleting old ico.dmi!"
		fdel("output/ico.dmi")

	// Create a blank icon to store icons into.
	var/icon/ico = new

	// Define our source rendering files.
	var/icon/diffuse = render_data.diffuse_map
	var/icon/normal  = render_data.normal_map
	var/icon/light   = render_data.light_map


	src << "Loaded diffuse, normal, and light icons!"
	// Insert the diffuse icon into the render.
	ico.Insert(diffuse, "diffuse")

	// Define and clone the normal icons for positive and negative color vectors.
	var/icon/normal_pos = icon(normal)
	var/icon/normal_neg = icon(normal)

	/**
	 * Adjust the colors in the positive normal by doubling their values.
	 * Then, shift the scale to the left, effectively truncating the lower half.
	 * This operation ensures that only values above 127 are retained.
	 */
	normal_pos.MapColors(
		2, 0, 0,
		0, 2, 0,
		0, 0, 2,
		-1, -1, -1
	)

	/**
	 * Alter the colors in the negative normal by inverting and doubling their values.
	 * Then, shift the scale to the right to emphasize lower values,
	 * ensuring that only values less than 128 are preserved.
	 */
	normal_neg.MapColors(
		-2, 0, 0,
		0, -2, 0,
		0, 0, -2,
		1, 1, 1
	)

	// Insert the normal icons into the render.
	ico.Insert(normal, "normal")
	ico.Insert(normal_pos, "normal_pos")
	ico.Insert(normal_neg, "normal_neg")

	src << "Began normal map operations!"

	//? Determine the direction you want to shine light from.
	var/x = -0.5 //! Assign the direction on the X axis.
	var/y = 1    //! Assign the direction on the Y axis.
	var/z = 0.25 //! Assign the direction on the Z axis.
	var/magnitude = sqrt(x ** 2 + y ** 2 + z ** 2) //! Determine the magnitude.

	// Normalize the axis.
	x /= magnitude
	y /= magnitude
	z /= magnitude

	// Create the light direction color.
	var/r = 128 + x * 128
	var/g = 128 + y * 128
	var/b = 128 + z * 128
	light.DrawBox(rgb(r, g, b), 1, 1, light.Width(), light.Height())

	// Define and clone the light directions to positive and negative.
	var/icon/light_pos = icon(light)
	var/icon/light_neg = icon(light)

	/**
	 * Adjust the colors in the positive normal by doubling their values.
	 * Then, shift the scale to the left, effectively truncating the lower half.
	 * This operation ensures that only values above 127 are retained.
	 */
	light_pos.MapColors(
		2, 0, 0,
		0, 2, 0,
		0, 0, 2,
		-1, -1, -1
	)
	/**
	 * Alter the colors in the negative normal by inverting and doubling their values.
	 * Then, shift the scale to the right to emphasize lower values,
	 * ensuring that only values less than 128 are preserved.
	 */
	light_neg.MapColors(
		-2, 0, 0,
		0, -2, 0,
		0, 0, -2,
		1, 1, 1
	)
	ico.Insert(light, "light")
	ico.Insert(light_pos, "light_pos")
	ico.Insert(light_neg, "light_neg")

	// Determine the amount of light cast into the normals and convert it into grayscale.
	light_pos *= normal_pos
	light_neg *= normal_neg
	light_pos.MapColors(
		0.66, 0.66, 0.66,
		0.66, 0.66, 0.66,
		0.66, 0.66, 0.66
	)
	light_neg.MapColors(
		0.66, 0.66, 0.66,
		0.66, 0.66, 0.66,
		0.66, 0.66, 0.66
	)
	ico.Insert(light_pos, "light_pos + normal_pos")
	ico.Insert(light_neg, "light_neg + normal_neg")

	/// Define and add the positive and negative lights together to illumination for the render.
	var/icon/illumination = light_pos + light_neg
	ico.Insert(illumination, "illumination")

	src << "Beginning full render!"

	// Do the full render by multiplying the diffuse icon with illumination
	// and multiplying that by the light color.
	var/icon/light_color = icon('icons/stairs.dmi', "") //! Define light color.
	light_color.DrawBox(rgb(254, 125, 19), 1, 1, light_color.Width(), light_color.Height())
	ico.Insert(light_color, "light_color")

	/// Define the render icon for the render.
	var/icon/render = diffuse * illumination * light_color
	ico.Insert(render, "render")

	// Add a reduced color palette version of the render for bonus.
	var/colors = 6
	var/color_step = 255 / (colors - 1)
	render /= color_step
	render *= color_step
	ico.Insert(render, "render_reduced")

	//# Write the sample images.

	src << "Writing ico.dmi!"
	fcopy(ico, "output/ico.dmi")

	var/list/icon/states = ico.IconStates()
	src << "List is [length(states)] long!"

	if(length(states))
		for(var/state in states)
			src << "Found state [state]!"
			var/file_name = "output/[state].png"
			if(fexists(file_name))
				src << "Backing up old sample [state]!"
				fcopy(file_name, "output/backup/[state].png")
				fdel(file_name)
				src << "Deleted old sample [state]!"

			fcopy(icon(ico, state), file_name)
			src << "Wrote sample [state]!"

		src << "FINISHED RENDER!"
	else
		src << "FAILED TO RENDER!"
		src << "No states found!"
