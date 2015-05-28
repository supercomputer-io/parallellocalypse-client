fs = require 'fs'
TEMP_DIR = "/sys/bus/iio/devices/iio:device0/"
TEMP_RAW_PATH = TEMP_DIR  + "in_temp0_raw"
TEMP_OFFSET_PATH = TEMP_DIR + "in_temp0_offset"
TEMP_SCALE_PATH = TEMP_DIR + "in_temp0_scale"

MIN_TEMP = process.env.THERMALD_MIN_TEMP or 0
MAX_TEMP = process.env.THERMALD_MAX_TEMP or 70

MIN_TEMP = 0 if MIN_TEMP < 0
MAX_TEMP = 85 if MAX_TEMP > 85

module.exports = {
	measureTemp: (done) ->
		fs.readFile TEMP_RAW_PATH, (err, rawTemp) ->
			throw err if err
			rawTemp = Number(rawTemp)
			fs.readFile TEMP_OFFSET_PATH, (err, tempOffset) ->
				throw err if err
				tempOffset = Number(tempOffset)
				fs.readFile TEMP_SCALE_PATH, (err, tempScale) ->
					throw err if err
					tempScale = Number(tempScale)
					temp = (rawTemp * tempScale / 1000) + tempOffset
					done(temp)


	checkTempWithinLimits: (cb) ->
		measureTemp (temp) ->
			if temp < MIN_TEMP
				console.log('Temperature below threshold')
				this.stop()
				cb()
			else if temp > MAX_TEMP
				console.log('Temperature above threshold')
				this.stop()
				cb()

	start: (cb) ->
		this.interval = setInterval ->
			checkTempWithinLimits(cb)
		, 1000

	stop: ->
		if this.interval?
			clearInterval(this.interval)
}
