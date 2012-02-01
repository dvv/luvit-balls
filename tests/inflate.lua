local inflate = require('../').inflate

local exports = { }

exports['inflate works'] = function (test)
  inflate(require('fs').read_file_sync(__dirname .. '/data.gz'), function (err, data)
    test.is_nil(err)
    test.equal(data, 'test\n')
    test.done()
  end)
end

return exports
