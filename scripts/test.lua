output = "<ul>\n"

for line in input:gmatch("[^\r\n]+") do
    output = output .. string.format("<li>%s</li>\n", line)
end

output = output .. "</ul>"

return output
