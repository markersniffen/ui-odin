sokol-shdc -i ../code/ui/shader.glsl -o ../code/ui/shader.odin -l glsl330:metal_macos:hlsl4 -f sokol_odin

odin build ../code --debug -define:TRACY_ENABLE=false
