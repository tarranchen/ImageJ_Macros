// Macro to set pixels outside an inscribed circle to zero for an entire stack.

width = getWidth();
height = getHeight();
if (width < height) {
  diameter = width;
} else {
  diameter = height;
}

x = (width - diameter) / 2;
y = (height - diameter) / 2;
makeOval(x, y, diameter, diameter);
run("Make Inverse");


setBackgroundColor(0, 0, 0);
run("Clear", "stack");
run("Select None");

print("Process complete: Pixels outside the inscribed circle have been set to 0 for the entire stack.");