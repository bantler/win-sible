-- -- starship.lua
os.setenv('STARSHIP_CONFIG', '$HOME\\.config\\starship.toml')
load(io.popen('starship init cmd'):read("*a"))()