import RayCaster as RC
import StaticArrays as SA
import MiniFB as MFB

const T = Float32

# img

const height_img = 512
const width_img = 256

const img = zeros(UInt32, height_img, width_img)
const fb = zeros(UInt32, width_img, height_img)

# colors

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const green = MFB.mfb_rgb(0, 255, 0)
const red = MFB.mfb_rgb(255, 0, 0)

# main

count = 128

function test_mfb()
    window = MFB.mfb_open("Test", width_img, height_img)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    while MFB.mfb_wait_sync(window)
        img[1:128, 1:64] .= green

        state = MFB.mfb_update(window, permutedims!(fb, img, (2, 1)))

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)
end

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        if key == MFB.KB_KEY_UP
            display(key)
            global count = count + 1
            img[count, 1:64] .= red
        elseif key == MFB.KB_KEY_DOWN
            display(key)
        elseif key == MFB.KB_KEY_LEFT
            display(key)
        elseif key == MFB.KB_KEY_RIGHT
            display(key)
        elseif key == MFB.KB_KEY_ESCAPE
            display(key)
            MFB.mfb_close(window)
        end
    end

    return nothing
end

test_mfb()
