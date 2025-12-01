✅ SHADOWS GAME — Official Demo (OGK Gaming × D.D. Tucker)

A Godot horror demo inspired by the novel Shadows Game: The War With Julian (Book 1) by D.D. Tucker.

This project is the official early game demo being developed in collaboration with the author, D.D. Tucker, as a playable adaptation of his book.

The goal is to capture the psychological horror, paranoia, memory distortion, and presence-in-the-dark themes central to the novel.

Author website:
https://booksbydttucker.com

Book page:
https://booksbydttucker.com/books/shadows-game-the-war-with-julian-book-1

🎮 About This Demo

This is an early prototype, built to test:

The tone & atmosphere of the Shadows Game universe

Player systems (movement, interaction, collecting)

Environmental storytelling

Camcorder + power cell survival mechanics

Heartbeat tension system

Cutscene + chapter transitions

A “floating house in space” and “museum hallway” as testbeds

Scares, pacing, and moment-to-moment gameplay

This demo does not follow the full book story yet.
It is a Proof of Feeling — testing the FEEL of the world first.

🧩 Core Systems — Based on What We Built in Chat
✔️ First-Person Player Controller

From our Godot sessions:

Smoothed head motion

Camera bob

Breathing SFX

Footstep system

Crouch + movement slowdown

Player interacts via raycast

Player sends events to GameEnhancer and ChapterManager

✔️ Camcorder System

Designed across multiple chats:

Toggle to turn on

Night vision effect

Battery drain

Power cell recharge mechanic moved entirely into GameEnhancer

Power Cells are collectible items

When used, they call GameEnhancer.recharge_camcorder()

HUD indicator for battery

✔️ Heartbeat System

We planned & implemented the foundation:

Looping heartbeat sound

Speed/frequency changes based on:

Darkness

Proximity to events

Story beats

Controlled through GameEnhancer so it’s not scatter-coded

✔️ Inventory Framework

Collectibles (Power Cells, keys, story objects)

Simple UI panel

Items have:

name

icon

description

script callback on use

Inventory integrates with camcorder + story triggers

✔️ Interaction System

We structured:

Doors

Drawers

Buttons

Pickup items

Triggers for jumpscares

World messages

All using a consistent interface so adding new interactables is easy.

✔️ Chapter / Cutscene System

Built after your cutscene discussions:

Plays intro video (“You wake up and your house is floating in deep space…”)

Black screen text cards

Timed transitions

Video playback + audio mixing

Ability to trigger chapters from map triggers

Clean handoff to next scene

Crash-proof/simple by design

✔️ Game Enhancer

This is your “central brain” for:

Heartbeat

Breathing

Camera bob

Camcorder logic

Power-cell recharge

Global effect switches

Future:

screen grain

stamina

fear meter

We talked countless times about moving logic OUT of other scripts and INTO GameEnhancer — this README finally reflects that architecture.

✔️ Environments

Based on your repo and chats:

1. Floating House (collhouse.tscn)

Prototype environment

Base demo area

First scares introduced here

2. Museum Hallway (bigmuseumcol.tscn)

Environmental contrast

Good for Chapter 2 testing

3. Monster / Shadow Entity (house_monster.tscn)

Early placeholder enemy

Used to test proximity fear + heartbeat effects

📁 Project Structure

Matches your repo AND your design choices:

/DemoPlayer
    player.tscn
    player.gd
    camera + breathing + footsteps

/Interaction
    door.tscn
    door.gd
    triggers
    pickups
    events

/Inventory
    inventory_ui.tscn
    item_base.gd
    collectible_item.gd
    item_database.gd
    power_cell.gd

levels/
    collhouse.tscn
    bigmuseumcol.tscn

cutscenes/
    intro.ogv
    video_intro.tscn

scripts/
    GameEnhancer.gd
    ChapterManager.gd
    canvas_layer.gd
    game_over.gd

▶️ How to Play
Install

Clone:

git clone https://github.com/OGKGaming/spacehouse


Open in Godot 4.x

Set collhouse.tscn as Main Scene

Press F5

⌨️ Controls

(You can update if needed.)

WASD – Move

Mouse – Look

E – Interact

Tab – Inventory

Right-Click – Toggle Camcorder

Shift – Run

Ctrl/C – Crouch

Esc – Pause

🛠️ Development Roadmap
Phase 1 — Prototype Systems ✔️

Player, camera bob, footsteps

Inventory + power cells

Camcorder + night vision

Heartbeat system

Intro cutscene

House + museum

Monster placeholder

Basic scares

Game Enhancer backend

Chapter Manager framework

Phase 2 — Book-Aligned Demo

Scenes inspired by early chapters

First appearance of Julian’s threat

Memory distortion events

Shadow presence encounters

Real dialogue / voiceover

First major chase or confrontation

Phase 3 — Full Playable Demo

20–30 min storyline

Cinematic storytelling

High-polish environments

Official itch.io release

📚 Credits

Story & World:
Shadows Game – The War With Julian (Book 1)
By D.D. Tucker
https://booksbydttucker.com

Game Development:
OGK Gaming

Engine:
Godot 4

Music / SFX:
Mix of custom + licensed + placeholders
(List will be expanded for release.)

📄 License

Code: MIT License

Book Lore, Characters, Narrative Elements:
Copyright © D.D. Tucker
Used with permission for this demo project
