
-- Utils helper functions
local bint = require('utils.bint')(256)

local utils = {
    add = function(a: string, b: string): string
      return tostring(bint(a) + bint(b))
    end,
    subtract = function(a: string, b: string): string
      return tostring(bint(a) - bint(b))
    end,
    toBalanceValue = function(a: number): string
      return tostring(bint(a))
    end,
    toNumber = function(a: string): number
      return tonumber(a)
    end
  }

  return utils