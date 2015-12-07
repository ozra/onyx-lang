type Greeter
    greeting–phrase = "Greetings,"
    -- greeting–phrase Str = "Greetings," -- a more explicit way

    init() ->
        -- do nothing - just keep defaults

    init(@greeting–phrase) ->
        -- do nothing here. Sugar for assigning a member did all we need!

    -- above could have been written more verbose; in many different levels.
    -- def init(greeting–phrase Str) ->
    --     @greeting–phrase = greeting–phrase
    -- end–def

    -- define a method that greets someone
    greet(who–or–what) ->!  -- returns nothing
        say make–greeting who–or–what
        -- say(make–greeting(who–or–what)) -- parentheses or "juxtapos-calls"

    -- a method that constructs the message
    make–greeting(who–or–what) ->
        "{{@greeting–phrase}} {{who–or–what}}"  -- returns last expression
    end  -- you can explicitly end code block at will

    -- All on one line works too of course:
    -- make–greeting(who–or–what) -> "{{@greeting–phrase}} {{who–or–what}}"

end–type -- you can be even more explicit about end–tokens at will

type HelloWorldishGreeter << Greeter
    greeting–phrase = "Hello"
end

greeter = HelloWorldishGreeter("Goodbye cruel")
greeter.greet "World" --  => "Goodbye cruel World"
-- greeter.greet_someone "World" -- separator (-|–|_) completely interchangable
