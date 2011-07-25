output = ""
inol = 0
inul = 0

for line in input:gmatch("[^\r\n]+") do
    pr = line:match("^\/(.*)\/")
    if pr then
        output = string.format("<span class=\"syntax\"><span d:pr=\"US\">| %s |</span></span>\n", pr) .. output
    else
        n = line:match("^%d+ ")
        if n then
            if tonumber(n) == 1 then
                output = output .. "<ol>\n"
                inol = 1
            end
            if inul == 1 then
                output = output .. "</ul></li>\n"
                inul = 0
            end
            output = output .. string.format("<li>%s\n", line:gsub("^%d+ ", ""))
        else
            if line:match("^\*") then
                if inul == 0 then
                    output = output .. "<ul>\n"
                    inul = 1
                end
                output = output .. string.format("<li>%s</li>\n", line:gsub("\*%s?", ""))
            else
                output = output .. line .. "\n"
            end
        end
    end
end

if inol == 1 then
    if inul == 1 then
        output = output .. "</ul></li>\n"
        inul = 0
    end
    output = output .. "</ol>"
    inol = 0
end

return output
