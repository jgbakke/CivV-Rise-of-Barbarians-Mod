--
-- Created by IntelliJ IDEA.
-- User: jordan
-- Date: 3/28/20
-- Time: 7:10 PM
-- To change this template use File | Settings | File Templates.
--

function Lshift(i, n)
    -- Shift i n spots to the left
    return math.floor(i * (2^n))
end

function Rshift(i, n)
    -- Shift i n spots to the right
    return math.floor(i / (2^n))
end

function CountBits(i)
    local iBits = 0
    -- Count the number of bits in i
    while i ~= 0 do
        if math.fmod(i, 2) == 1 then
            iBits = iBits + 1
        end

        i = Rshift(i, 1)
    end

    return iBits
end