import Nettle

function solution_hash(word::UTF8String, nick::UTF8String)
    Nettle.hexdigest("sha256", word * nick)
end