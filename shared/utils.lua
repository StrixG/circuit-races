function getPluralString(count, pluralForms)
  local lastDigit = count % 10
  if count % 100 >= 11 and count % 100 <= 14 then
    return pluralForms[1]
  elseif lastDigit == 1 then
    return pluralForms[2]
  elseif lastDigit >= 2 and lastDigit <= 4 then
    return pluralForms[3]
  else
    return pluralForms[1]
  end
end

function numberFormat(value, sep)
  if sep == nil then
    sep = ','
  end
  local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
  return left .. (num:reverse():gsub('(%d%d%d)','%1' .. sep):reverse()) .. right
end

function findRotation3D(x1, y1, z1, x2, y2, z2)
  local rotX = math.atan2(z2 - z1, getDistanceBetweenPoints2D(x2, y2, x1, y1))
  rotX = math.deg(rotX)

  local rotZ = -math.deg(math.atan2(x2 - x1, y2 - y1))
  rotZ = rotZ < 0 and rotZ + 360 or rotZ

  return rotX, 0, rotZ
end

function removeHexFromString(string)
	return string.gsub(string, "#%x%x%x%x%x%x", "")
end