xcorr = require './build/Release/xcorr'
request = require 'superagent'
Jimp = require 'jimp'
config = require './config.json'
getMac = require('getmac').getMac
_ = require 'lodash'

getMac (err,myMacAddress) ->

	hubImagesUrl = 'http://localhost:8080/images/'

	pubnub = require("pubnub")({
	    publish_key   : config.publish_key,
	    subscribe_key : config.subscribe_key,
	    uuid: myMacAddress
	})

	pubnub.subscribe({
		channel: 'work',
		heartbeat: 10,
		message: (m) -> console.log("new work! " + m)
	})

	processWork = (work) ->
		pubnub.publish({
			channel: 'working'
			message: myMacAddress
		})
		targetImage = work.targetImage
		results = []
		amountDone = 0
		whenDone = () ->
			console.log('Done!')
			console.log(results)
			theResult = _.max(results, 'value')

			pubnub.publish({
				channel: 'results'
				message: theResult
			})

		correlate = (ind, img, image1) ->
			console.log('Correlating #' + (ind+1))
			image2URL = hubImagesUrl + img.original_img
			request.get(image2URL).end (req, res) ->
				image2Buffer = res.body
				new Jimp image2Buffer, (err, image2) ->
					console.log('Result for #' + (ind + 1))
					result = xcorr(image1.bitmap.data, image2.bitmap.data)
					console.log(result)
					results[ind] = {
						value: result
						name: img.personName
						imageId: img.id
					}
					amountDone += 1
					if(amountDone == work.workSize)
						whenDone()

		request.get(hubImagesUrl + work.targetImage.url).end (req, res) ->
			image1Buffer = res.body
			new Jimp image1Buffer, (err, image1) ->
				ind = 0
				_.each work.images, (img) ->
					correlate(ind, img, image1)
					ind += 1
					


	pubnub.subscribe({
		channel: myMacAddress
		message: processWork
	})
