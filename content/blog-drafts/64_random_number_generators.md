% TITLE (DEV-TIP) Weird Random Number Generators
% DESCRIPTION I love pseudo-random number generators. Here's a collection of non-tried weird random number generators I came up with.
% DATE 28.11.2024


        var randSeed = 1923;
        function sin_rand() {
            randSeed += Math.sin(randSeed) * 1000000000;
            return (randSeed & 0xFFFFFFF) / 0xFFFFFFF;
        }
