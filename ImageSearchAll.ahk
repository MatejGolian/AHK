ImageSearchAll(imageFile, x1:=0, y1:=0, x2:='Screen', y2:='Screen', var:=0) {
	x2 := x2 = 'Screen' ? A_ScreenWidth : x2
	y2 := y2 = 'Screen' ? A_ScreenHeight : y2
	found := []
	y := y1
	loop {
		x := x1
	    lastFoundY := 0
		while f := ImageSearch(&foundX, &foundY, x, y, x2, y2, '*' var ' ' imageFile) {
			if (lastFoundY = 0 || lastFoundY = foundY) {
				found.Push({x: foundX, y: foundY})
				x := foundX + 1
				lastFoundY := foundY
			} else
				break
		}
		y := lastFoundY + 1
	} until (x = x1) && !f
	return found
}
