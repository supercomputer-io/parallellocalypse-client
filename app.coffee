xcorr = require './build/Release/xcorr'
request = require 'superagent'
Jimp = require 'jimp'


image1URL = 'http://img.removedfromgame.com/imgs/Nyan%20Cat(StretchedSquare).bmp'
image2URL = 'http://img.removedfromgame.com/imgs/Nyan%20Cat(StretchedSquare).bmp'

request.get(image1URL).end (req, res) ->
	image1Buffer = res.body
	new Jimp image1Buffer, (err, image1) ->
		request.get(image2URL).end (req, res) ->
			image2Buffer = res.body
			new Jimp image2Buffer, (err, image2) ->
				console.log(xcorr(image1.bitmap.data, image2.bitmap.data));
