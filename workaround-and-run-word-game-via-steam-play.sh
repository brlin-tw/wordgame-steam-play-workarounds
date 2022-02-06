#!/bin/bash
# Run 文字遊戲(Word Game) on Linux by applying some workarounds
#
# Based on script generated by the Proton (Steam Play compatibility tool
#
# Copyright 2021 林博仁(Buo-ren, Lin) <Buo.Ren.Lin@gmail.com>
# SPDX-License-Identifier: CC-BY-SA-4.0

GODOT_VERBOSE="${GODOT_VERBOSE:-false}"
STEAM_LIBRARY_DIR="${STEAM_LIBRARY_DIR:-"${HOME}/.local/share/Steam"}"
WINEDEBUG="${WINEDEBUG:--all}"
STEAM_PLAY_VERSION="${STEAM_PLAY_VERSION:-"Proton Experimental"}"

set \
    -o errexit \
    -o nounset

steamapps_common_dir="${STEAM_LIBRARY_DIR}/steamapps/common"
steamapps_compatdata_dir="${STEAM_LIBRARY_DIR}/steamapps/compatdata"
word_game_installation_dir="${steamapps_common_dir}/文字遊戲"
word_game_main_executable="${word_game_installation_dir}/文字遊戲.exe"
# For outputing MINDTYPER files to the real user's desktop
steamuser_desktop_dir="${steamapps_compatdata_dir}/1109570/pfx/drive_c/users/steamuser/Desktop"

printf 'Info: Checking runtime environment...\n'
case "${STEAM_PLAY_VERSION}" in
    'Proton '*.*-*)
        # Drop the version suffix which is not included in the paths
        STEAM_PLAY_VERSION="${STEAM_PLAY_VERSION%-*}"
        proton_dist_dir="${steamapps_common_dir}/${STEAM_PLAY_VERSION}/dist"
    ;;
    'Proton Experimental')
        STEAM_PLAY_VERSION='Proton - Experimental'
        proton_dist_dir="${steamapps_common_dir}/${STEAM_PLAY_VERSION}/files"
    ;;
    *)
        printf \
            'Error: Unsupported Steam Play version.\n' \
            1>&2
        exit 1
    ;;
esac
steam_play_dir="${proton_dist_dir%/*}"
printf \
    'Info: Using Proton distribution located at "%s".\n' \
    "${steam_play_dir}"

if ! test -e "${proton_dist_dir}"; then
    printf \
        'Error: Unable to locate Proton dist/files directory at "%s".\n' \
        "${proton_dist_dir}" \
        1>&2
    exit 2
fi

printf 'Info: Applying real desktop workarounds...\n'
if ! test -e ~/.config/user-dirs.dirs; then
    real_user_desktop_dir="${HOME}/Desktop"
else
    # External resource, don't care
    # shellcheck source=/dev/null
    source ~/.config/user-dirs.dirs
    if ! test -v XDG_DESKTOP_DIR; then
        real_user_desktop_dir="${HOME}/Desktop"
    else
        real_user_desktop_dir="${XDG_DESKTOP_DIR}"
    fi
fi

if ! test -L "${steamuser_desktop_dir}"; then
    rm \
        --force \
        --recursive \
        --verbose \
        "${steamuser_desktop_dir}"

    mkdir \
        --parents \
        "${steamuser_desktop_dir%/*}"

    ln \
        --no-target-directory \
        --symbolic \
        --verbose \
        "${real_user_desktop_dir}" \
        "${steamuser_desktop_dir}"
fi

printf 'Info: Running game with workarounded configuration...\n'

cd "${word_game_installation_dir}"
DEF_CMD=("${word_game_main_executable}")
if test "${GODOT_VERBOSE}" == true; then
    DEF_CMD+=(--verbose)
fi

env \
    GST_PLUGIN_SYSTEM_PATH_1_0="${proton_dist_dir}/lib64/gstreamer-1.0:${proton_dist_dir}/lib/gstreamer-1.0" \
    LD_LIBRARY_PATH="${proton_dist_dir}/lib64/:${proton_dist_dir}/lib/:/usr/lib/pressure-vessel/overrides/lib/x86_64-linux-gnu/aliases:/usr/lib/pressure-vessel/overrides/lib/i386-linux-gnu/aliases" \
    MEDIACONV_AUDIO_DUMP_FILE="${STEAM_LIBRARY_DIR}/steamapps/shadercache/1109570/fozmediav1/audio.foz" \
    MEDIACONV_AUDIO_TRANSCODED_FILE="${STEAM_LIBRARY_DIR}/steamapps/shadercache/1109570/transcoded_audio.foz" \
    MEDIACONV_VIDEO_DUMP_FILE="${STEAM_LIBRARY_DIR}/steamapps/shadercache/1109570/fozmediav1/video.foz" \
    MEDIACONV_VIDEO_TRANSCODED_FILE="${STEAM_LIBRARY_DIR}/steamapps/shadercache/1109570/transcoded_video.foz" \
    PATH="${proton_dist_dir}/bin/:/usr/bin:/bin" \
    SteamAppId="1109570" \
    SteamGameId="1109570" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam" \
    TERM="xterm" \
    WINEDLLOVERRIDES="steam.exe=b;dotnetfx35.exe=b;beclient.dll=b,n;beclient_x64.dll=b,n;dxvk_config=n;d3d11=n;d3d10=n;d3d10core=n;d3d10_1=n;d3d9=n;dxgi=n" \
    WINEDLLPATH="${proton_dist_dir}/lib64/wine:${proton_dist_dir}/lib/wine" \
    WINEESYNC="1" \
    WINEFSYNC="1" \
    WINEPREFIX="${STEAM_LIBRARY_DIR}/steamapps/compatdata/1109570/pfx/" \
    WINE_GST_REGISTRY_DIR="${STEAM_LIBRARY_DIR}/steamapps/compatdata/1109570/gstreamer-1.0/" \
    WINE_LARGE_ADDRESS_AWARE="1" \
    "${proton_dist_dir}/bin/wine64" \
    "${@:-${DEF_CMD[@]}}"
