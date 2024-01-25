{ pkgs }:

[
    {
        name = "nova";
        type = "git";
        hash = "33fbac63a46a1d91daa48833fb17e0ab4b0a04c7";

        url = "https://github.com/alex-ab/NOVA.git";
        rev = "3e34fa6c35c55566ae57a1fd654262964ffcf544";
        dir = "src/kernel/nova";
    }

    {
        name = "grub2";
        type = "git";
        hash = "80d41dfe8a1d8d8a80c51f446553b7d28c3ce395";

        url = "https://github.com/alex-ab/g2fg.git";
        rev = "0d94ee016a3a4f991f502d04ef59e7d0d8e75346";
        dir = "boot";
    }
]