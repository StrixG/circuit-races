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