fs = require('fs')
if !fs.existsSync('config.json')
	module.exports = {
		subscribe_key: process.env.PUBNUB_SUB_KEY
		publish_key: process.env.PUBNUB_PUB_KEY
		secret: process.env.SERVER_SECRET
		hubUrl: process.env.HUB_URL
		hubImagesUrl: process.env.HUB_IMAGES_URL
	}
else
	module.exports = JSON.parse(fs.readFileSync('config.json', encoding: 'utf-8'))
