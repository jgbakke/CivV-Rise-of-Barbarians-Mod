--
-- Created by IntelliJ IDEA.
-- User: jordan
-- Date: 3/28/20
-- Time: 7:10 PM
-- To change this template use File | Settings | File Templates.
--

-- thank you kind stranger: https://stackoverflow.com/questions/32387117/bitwise-and-in-lua

BIT_OPERATIONS = {OR=1, XOR=3, AND=4}

function bitoper(a, b, oper)
   local r, m, s = 0, 2 ^ 52, nil
    repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*oper%(s-a-b), m/2
   until m < 1
   return r
end

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
        if bitoper(i, 1, BITOPERATIONS.AND) == 1 then
            iBits = iBits + 1
        end

        i = Rshift(i, 1)
    end

    return iBits
end