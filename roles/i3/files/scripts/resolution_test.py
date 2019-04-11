import resolution

def set_up_object():
    runner = resolution.Runner("../")
    # Override all words that are defined in real implementation.
    runner.words_to_parse = {}
    runner.words_to_parse['TEST'] = 'foo'
    runner.words_to_parse['foo'] = 'bar'

    return runner

def test_parse_line_one():
    test_obj = set_up_object()

    test_line = "$$TEST$$"
    should_be = "foo"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_one_left_pad():
    test_obj = set_up_object()

    test_line = "junk$$TEST$$"
    should_be = "junkfoo"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_one_right_pad():
    test_obj = set_up_object()

    test_line = "$$TEST$$junk"
    should_be = "foojunk"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_one_both_pad():
    test_obj = set_up_object()

    test_line = "junk$$TEST$$isbad"
    should_be = "junkfooisbad"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_two():
    test_obj = set_up_object()

    test_line = "$$TEST$$$$foo$$"
    should_be = "foobar"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_two_left_pad():
    test_obj = set_up_object()

    test_line = "junk$$TEST$$$$foo$$"
    should_be = "junkfoobar"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_two_right_pad():
    test_obj = set_up_object()

    test_line = "$$TEST$$$$foo$$food"
    should_be = "foobarfood"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_two_both_pad():
    test_obj = set_up_object()

    test_line = "junk$$TEST$$$$foo$$food"
    should_be = "junkfoobarfood"

    assert test_obj.parse_line(test_line) == should_be

def test_parse_line_two_both_pad_space():
    test_obj = set_up_object()

    test_line = "junk$$TEST$$space$$foo$$food"
    should_be = "junkfoospacebarfood"

    assert test_obj.parse_line(test_line) == should_be

def test_no_match():
    test_obj = set_up_object()

    test_line = "$$notexist$$"
    should_be = "doesnotmatter"

    try:
        test_obj.parse_line(test_line)
        assert False
    except resolution.CouldNotParseException:
        assert True
