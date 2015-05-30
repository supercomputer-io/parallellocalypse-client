console.log(process.env.MOCK_MAC)
if process.env.MOCK_MAC
	xcorr = require './lib/mock_xcorr'
	thermald = null
else
	xcorr = require './build/Release/xcorr'
	thermald = require './lib/thermald'

request = require 'superagent'
bcrypt = require 'bcrypt-nodejs'
require('superagent-cache')(request, {
	cacheServiceConfig: {},
	cacheModuleConfig: [
		{
			type: 'node-cache'
			defaultExpiration: 7200
		}
	]
})

config = require './config'

_ = require 'lodash'
fs = require 'fs'

console.log('Starting up...')

#TO-DO: load from file
dbimages = {}

getMac = (cb) ->
	fs.readFile '/sys/class/net/eth0/address', (err, data) ->
		if err
			cb(err)
		else
			cb(null, data.toString().trim())

getMac (err, myMacAddress) ->

	registerWithServer = (status = 'Idle', cb = null) ->
		console.log('Registering...')
		request.get('http://ipinfo.io/json').end (err, loc) ->
			location = loc.body or {}
			request.post(hubUrl + 'api/devices')
			.send({
				resinId: process.env.RESIN_DEVICE_UUID
				macAddress: myMacAddress
				secret: bcrypt.hashSync(myMacAddress + config.secret)
				location
				status
			}).end (err, res) ->
				if err
					console.log(err)
				else
					console.log(res.body)
				if(cb?)
					cb()

	if process.env.MOCK_MAC
		myMacAddress = process.env.MOCK_MAC


	hubUrl = config.hubUrl or 'http://localhost:8080/'
	hubImagesUrl = config.hubImagesUrl or 'http://parallellocalypse.s3-website-us-east-1.amazonaws.com'

	registerWithServer "Idle", ->
		if thermald?
			thermald.start ->
				console.log("Temperature beyond limits. Gracefully crashing.")
				registerWithServer "Overheating", ->
					process.exit(0)

	pubnub = require('pubnub')({
		origin: 'resin.pubnub.com'
		publish_key: config.publish_key
		subscribe_key: config.subscribe_key
		uuid: myMacAddress
	})

	console.log('Subscribing...')
	pubnub.subscribe({
		channel: 'work',
		heartbeat: 10,
		state: {
			status: 'Started'
			chunkId: null
		},
		message: (m) -> console.log(m)
	})

	processWork = (work) ->
		console.log('Starting task.')
		startTime = Date.now()

		pubnub.state({
			channel: 'work'
			state: {
				status: 'Working'
				chunkId: work.chunkId
			}
		})
		pubnub.publish({
			channel: 'working'
			message: {
				device: myMacAddress
				progress: 0
			}
		})
		targetImage = work.targetImage
		results = []
		amountDone = 0
		whenDone = ->
			console.log('Done!')
			theResult = _.max(results, 'value')
			theResult.device = myMacAddress
			theResult.elapsedTime = Date.now() - startTime
			console.log(theResult)
			pubnub.publish({
				channel: 'working'
				message: {
					device: myMacAddress
					progress: 100
				}
			})

			pubnub.state({
				channel: 'work'
				state: {
					status: 'Idle'
					chunkId: null
				}
			})

			pubnub.publish({
				channel: 'results'
				message: theResult
			})

		whenDone2 = (theResult) ->
			console.log('Done!')
			
			console.log(theResult)
			pubnub.publish({
				channel: 'working'
				message: {
					device: myMacAddress
					progress: 100
				}
			})

			pubnub.state({
				channel: 'work'
				state: {
					status: 'Idle'
					chunkId: null
				}
			})

			pubnub.publish({
				channel: 'results'
				message: theResult
			})

		progress = 0
		onProgress = (amountDone, totalSize) ->
			percent = amountDone * 100 / totalSize
			if Math.floor(percent / 10) > Math.floor(progress / 10)
				pubnub.publish({
					channel: 'working'
					message: {
						device: myMacAddress
						progress: percent
					}
				})
				progress = percent

		correlate = (ind, img, image1) ->
			
			image2 = dbimages[img.uuid]
			xcorr image1, image2.data, (result) ->
				results[ind] = {
					value: result
					name: image2.image.personName
					imageId: image2.image.id
					imageUrl: image2.image.path
					chunkId: work.chunkId
				}
				amountDone += 1
				onProgress(amountDone, work.workSize)
				if(amountDone == work.workSize)
					whenDone()

		correlate2 = (images, image1) ->
			onProgress(0, images.length)
			imgArray = []
			for i in [0...images.length]
				if ! dbimages[images[i].uuid]?
					throw "Image not in cache - can't do it"
				imgArray[i] = dbimages[images[i].uuid].data

			xcorr image1, imgArray, (res) ->
				theResult = {}
				theResult.value = _.max(res)
				theResult.device = myMacAddress
				theResult.elapsedTime = Date.now() - startTime
				ind = _.indexOf(res, theResult.value)
				theImage = dbimages[images[ind].uuid]
				theResult.name = theImage.image.personName
				theResult.imageId = theImage.image.id
				theResult.imageUrl = theImage.image.path
				theResult.chunkId = work.chunkId
				whenDone2(theResult)


		console.log('Getting:')
		console.log(hubImagesUrl + work.targetImage)
		request.get(hubImagesUrl + work.targetImage).end (req, res) ->
			image1 = res.body
			correlate2(work.images, image1)
			#_.each work.images, (img, ind) ->
			#	correlate(ind, img, image1)

	pubnub.subscribe({
		channel: myMacAddress
		message: processWork
	})

	warmCache = (data) ->
		pubnub.state({
			channel: 'work'
			state: {
				status: 'Warming up'
			}
		})
		console.log("Warming cache")
		images = data.images
		_.each images, (img, ind) ->
			request.get(hubImagesUrl + img.path).end (err, res) ->
				if err
					throw err
				dbimages[img.uuid] = {
					image: img
					data: res.body
				}
				if ind == (images.length - 1)
					console.log('Done')
					if data.page == data.nPages
						pubnub.state({
							channel: 'work'
							state: {
								status: 'Idle'
							}
						})

	pubnub.subscribe({
		channel: 'images'
		message: warmCache
	})

	console.log('Ready.')
