
// Test for https://github.com/ooc-lang/rock/issues/346

import structs/HashBag

Pair: class <Kakhi, V> {
    kik: Kakhi
    v: V

    init: func (=kik, =v) {}
}

index := 0

gprint: func <Tina> (t: Tina) {
    r := match t {
        case i: Int    => "#{i}"
        case s: String => "#{s}"
        case => "nope"
    }
    match index {
        case 0 => expect("Hello", r)
        case 1 => expect("World!", r)
        case 2 => expect("leet", r)
        case 3 => expect("1337", r)
    }
    index += 1
}

operator => <K, V> (k: K, v: V) -> Pair<K, V> { Pair<K, V> new(k, v) }

hashbag: func (args: ...) {
    args each(|arg|
        pair := arg as Pair
        gprint(pair kik)
        gprint(pair v)
    )
}

describe("should refer to typeArg from owner, not 'this'", ||
    hashbag("Hello" => "World!", "leet" => 1337)
)


