local Zip = require('./lib/zip')

-- export
return {
  unzip = Zip.unzip,
  inflate = Zip.inflate,
}
