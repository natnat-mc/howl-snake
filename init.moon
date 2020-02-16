import signal, command, timer, app, ui from howl
import ActionBuffer from ui

class Snake
	new: =>
		@buffer=ActionBuffer!
		@score=0
		@size={x: 15, y: 15}
		@direction={x: 1, y: 0}
		@food={x: 2, y: 4}
		@head={x: 5, y: 5}
		@body={{x: 3, y: 5}, {x: 4, y: 5}}
		@ended=false
		@speed=1
		@onclose= (params) ->
			@die! if params.buffer==@buffer
		signal.connect 'buffer-closed', @onclose

	start: =>
		app\add_buffer @buffer, true
		timer.asap @\tick

	tick: =>
		return if @ended
		@handleinput!
		table.remove @body, 1
		table.insert @body, @head
		@head=
			x: @head.x+@direction.x
			y: @head.y+@direction.y
		@head.x=1 if @head.x>@size.x
		@head.y=1 if @head.y>@size.y
		@head.x=@size.x if @head.x==0
		@head.y=@size.y if @head.y==0
		if @head.x==@food.x and @head.y==@food.y
			@eat!
		for section in *@body
			if @head.x==section.x and @head.y==section.y
				@die!
		@render!
		timer.after @speed, @\tick unless @ended

	handleinput: =>
		editor=app\editor_for_buffer @buffer
		local dir
		if editor.cursor.column==1
			dir={x: -1, y: 0}
		elseif editor.cursor.column==3
			dir={x: 1, y: 0}
		elseif editor.cursor.line==@size.y+3
			dir={x: 0, y: -1}
		elseif editor.cursor.line==@size.y+5
			dir={x: 0, y: 1}
		if dir
			if (dir.x!=0 and dir.x!=-@direction.x) or (dir.y!=0 and dir.y!=-@direction.y)
				@direction=dir

	render: =>
		lines=[ [' ' for j=1, @size.x] for i=1, @size.y] -- empty grid
		lines[@food.y][@food.x]='#' -- food
		lines[section.y][section.x]='+' for section in *@body -- body
		lines[@head.y][@head.x]='@' -- head
		content="+#{string.rep '-', @size.x}+\n" -- top border
		content..=table.concat ["|#{table.concat lines[i]}|" for i=1, #lines], '\n' -- game area
		content..="\n+#{string.rep '-', @size.x}+\n" -- bottom border
		content..=" U\nL R\n D" -- joystick
		@buffer.text=content
		editor=app\editor_for_buffer @buffer
		editor.cursor.column=2
		editor.cursor.line=@size.y+4
		@buffer.modified=false

	eat: =>
		acceptable= ->
			return false if @food.x==@head.x and @food.y==@head.y
			for section in *@body
				return false if @food.x==section.x and @food.y==section.y
			return true
		randompos= ->
			x: (math.random @size.x), y: (math.random @size.y)
		@food=randompos!
		while not acceptable!
			@food=randompos!
		table.insert @body, @body[#@body]
		@score+=1
		@speed*=.9

	die: =>
		@ended=true
		app.close_buffer, @buffer, true
		signal.disconnect 'buffer-closed', @onclose

command.register
	name: 'snake'
	description: 'A simple snake game'
	handler: ->
		game=Snake!
		game\start!

unload= ->
	command.unregister 'snake'

{
	info:
		author: "Codinget"
		description: "A simple snake game in the Howl editor"
		license: 'MIT'
	:unload
}
