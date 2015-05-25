Jimp = require('jimp')
xcorr = (img1, img2, done) ->
	new Jimp img1, (err, image1) ->
		new Jimp img2, (err, image2) ->
			result = 0
			n = image2.bitmap.data.length
			for i in [0...n]
				if image1.bitmap.data[i]? and image2.bitmap.data[i]?
					result += image1.bitmap.data[i] * image2.bitmap.data[i]

			result /= (n^2)

			done(result)

module.exports = xcorr