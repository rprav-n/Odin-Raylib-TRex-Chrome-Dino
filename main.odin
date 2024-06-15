package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

GAME_NAME :: "T-Rex Dino Run"
WINDOW_WIDTH :: 600
WINDOW_HEIGHT :: 150
PADDING :: 10
JUMP_SPEED :: -10
GRAVITY: f32 : 34
DINO_SPRITE_START_POS_X: f32 : 721.0
DEBUG :: false

Cloud :: struct {
	x: f32,
	y: f32,
	speed: f32
}


Cactus :: struct {
	x: f32,
	y: f32,
	speed: f32,
	cactus_src: rl.Rectangle
}

clouds: [dynamic]Cloud
cactuses: [dynamic]Cactus




main :: proc() {
	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, GAME_NAME)

	all_texture := rl.LoadTexture("sprite_sheet.png")

	game_over := false
	
	// For Dino
	dino_source := rl.Rectangle{DINO_SPRITE_START_POS_X, 0, 44, 49}
	dino_ground_pos_y := WINDOW_HEIGHT-dino_source.height - 7
	dino_dest := rl.Rectangle{10, dino_ground_pos_y, dino_source.width, dino_source.height}
	velocity: f32 = 0
	can_jump := true
	on_ground := true
	total_frames := 2
	frame := 0
	update_time : f32 = 1.0/12.0
	running_time: f32 = 0.0

	// For Ground
	ground_source := rl.Rectangle{2, 54, cast(f32)all_texture.width - 20, 10}
	ground_one_dest := rl.Rectangle{0, WINDOW_HEIGHT - ground_source.height - PADDING, ground_source.width, ground_source.height }
	ground_two_dest := rl.Rectangle{ground_one_dest.width+100, ground_one_dest.y, ground_source.width, ground_source.height }
	ground_speed: f32 = 4.0

	// For Cloud
	cloud_source := rl.Rectangle{86, 0, 46, 15}
	cloud_time_initial: f32 = 3.0
	cloud_time: f32 = 0.0

	// For small cactus
	small_cactus_source := rl.Rectangle{228, 2, 17, 35}
	small_cactus_total_count := 6
	large_cactus_source := rl.Rectangle{332, 2, 25, 50}
	large_cactus_total_count := 4
	cactus_time_initial: f32 = 1.0
	cactus_time: f32 = 0.0

	// For game over
	game_over_src := rl.Rectangle{484, 15, 191, 11}


	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {

		if game_over {
			if rl.IsKeyPressed(rl.KeyboardKey.R) {
				game_over = false
				clear_dynamic_array(&cactuses)
				dino_dest := rl.Rectangle{10, dino_ground_pos_y, dino_source.width, dino_source.height}
				frame = 0
			}
			dino_source.x = (3.0 * dino_source.width) + DINO_SPRITE_START_POS_X
		} else {
			dt: f32 = rl.GetFrameTime()
			running_time += dt
			cloud_time += dt
			cactus_time += dt

			if cloud_time > cloud_time_initial {
				cloud_time = 0.0
				spawn_cloud(cloud_source)
			}

			if cactus_time > cactus_time_initial {
				cactus_time = 0.0
				cactus_time_initial = rand.float32_range(0.5, 1.5)
				fmt.println(cactus_time_initial)
				cactus_src := small_cactus_source
				if cactus_time_initial > 0.75 {
					cactus_src  = large_cactus_source
				}
				spawn_cactus(cactus_src)
			}

			// ground movement
			ground_one_dest.x -= ground_speed
			ground_two_dest.x = ground_one_dest.x + ground_one_dest.width
			if ground_one_dest.x < -ground_source.width {
				ground_one_dest.x = 0
			}

			// dino gravity
			velocity += GRAVITY * dt

			// dino jump
			if rl.IsKeyPressed(rl.KeyboardKey.SPACE) && can_jump {
				velocity = JUMP_SPEED
				can_jump = false
				on_ground = false
			}

			dino_dest.y += velocity

			// dino ground check
			if dino_dest.y > dino_ground_pos_y {
				dino_dest.y = dino_ground_pos_y
				on_ground = true
				can_jump = true
			}

			// dino animation
			if running_time >= update_time {
				running_time = 0.0
				if !on_ground {
					frame = 0	
				} else {
					frame += 1
				}
				
				dino_source.x = (cast(f32)frame * dino_source.width) + DINO_SPRITE_START_POS_X
				if frame >= total_frames {
					frame = 0
				}
			}
			
			// update clouds
			for &cloud in clouds {
				cloud.x -= cloud.speed
			}

			// update cactus
			for &cactus in cactuses {
				cactus.x -= cactus.speed
			}

			//  remove clouds
			for cloud, index in clouds {
				if cloud.x + cloud_source.width < 0 {
					unordered_remove(&clouds, index)
				}
			}

			// remove cactuses
			for cactus, index in cactuses {
				if cactus.x + cactus.cactus_src.width < 0 {
					ordered_remove(&cactuses, index)
				}
			}

		}

		// check for dino and cactuses collision
		for cactus in cactuses {
			if rl.CheckCollisionRecs(
				rl.Rectangle{cactus.x, cactus.y, cactus.cactus_src.width, cactus.cactus_src.height},
				dino_dest
			) {
				game_over = true
			}
		}
		

		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)

		// draw clouds
		for cloud in clouds {
			rl.DrawTextureRec(all_texture, cloud_source, rl.Vector2{cloud.x, cloud.y}, rl.WHITE)
		}

		// draw ground
		rl.DrawTexturePro(all_texture, ground_source, ground_one_dest, rl.Vector2{}, 0.0, rl.WHITE)
		rl.DrawTexturePro(all_texture, ground_source, ground_two_dest, rl.Vector2{}, 0.0, rl.BLACK)

		// draw cactuses
		for cactus in cactuses {
			rl.DrawTextureRec(all_texture, cactus.cactus_src, rl.Vector2{cactus.x, cactus.y}, rl.WHITE)
			if DEBUG {
				rl.DrawRectangleLinesEx(
					rl.Rectangle{cactus.x, cactus.y, cactus.cactus_src.width, cactus.cactus_src.height},
					2.0, rl.BLUE
				)
			}
			
		}

		// draw dino
		rl.DrawTexturePro(all_texture, dino_source, dino_dest, rl.Vector2{}, 0.0, rl.WHITE)

		if DEBUG {
			rl.DrawRectangleLinesEx(dino_dest,2.0, rl.BLUE)
		}

		if game_over {
			rl.DrawTextureRec(all_texture, game_over_src, rl.Vector2{WINDOW_WIDTH/2-game_over_src.width/2, WINDOW_HEIGHT/4}, rl.WHITE)

			// rl.DrawTexturePro(all_texture, game_over_src, rl.Rectangle{WINDOW_WIDTH/2, WINDOW_HEIGHT/2, game_over_src.width, game_over_src.height}, rl.Vector2{game_over_src.width/2, game_over_src.height/2}, 0.0, rl.WHITE)
		}
		

		rl.EndDrawing()
	}
}


spawn_cloud :: proc(cloud_src: rl.Rectangle) {
	cloud := Cloud {
		WINDOW_WIDTH,
		rand.float32_range(0.0, WINDOW_HEIGHT/2.0),
		1.0
	}
	append(&clouds, cloud)
}


spawn_cactus :: proc(cactus_src: rl.Rectangle) {
	cactus := Cactus {
		WINDOW_WIDTH,
		WINDOW_HEIGHT - PADDING - cactus_src.height + 4,
		4.0,
		cactus_src
	}
	append(&cactuses, cactus)
}