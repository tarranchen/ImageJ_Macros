// 1. Select the target directory containing the TIF sequence
dir = getDirectory("Choose a directory containing the TIF sequence");
if (dir == "") {
    exit("No directory selected. Macro terminated.");
}

// Extract the parent directory name and path for the final output
// Convert all slashes to standard forward slashes for cross-platform compatibility
cleanDir = replace(dir, "\\", "/");
if (endsWith(cleanDir, "/")) {
    cleanDir = substring(cleanDir, 0, lengthOf(cleanDir)-1);
}
pathParts = split(cleanDir, "/");

// Index [pathParts.length - 1] is the current folder (e.g., "TIF")
// Index [pathParts.length - 2] is the parent folder (e.g., "Al15_0")
parentDirName = pathParts[pathParts.length - 2];

// Extract the parent directory path for saving files (e.g., X:/.../Al15_0/)
saveDir = substring(cleanDir, 0, lastIndexOf(cleanDir, "/")) + "/";

// 2. Load the background image (_01_) and perform median projection, then close the original stack immediately
File.openSequence(dir, " filter=_01_");
rename("Bg_Stack");
imgBg = "Bg_Stack";

selectWindow(imgBg);
run("Z Project...", "projection=Median");
medBg = getTitle();
selectWindow(imgBg); close();

// 3. Load the sample image (_02_) and perform median projection, then close the original stack immediately
File.openSequence(dir, " filter=_02_");
rename("Sample_Stack");
imgSample = "Sample_Stack";

selectWindow(imgSample);
run("Z Project...", "projection=Median");
medSample = getTitle();
selectWindow(imgSample); close();

// 4. Load the single dark field image
File.openSequence(dir, " filter=df");
rename("Dark_Image");
imgDark = "Dark_Image";

// 5. Image math: subtract dark field, then close the used projection and dark field images immediately
imageCalculator("Subtract create 32-bit", medSample, imgDark);
subSample = getTitle();
selectWindow(medSample); close(); // Release sample projection

imageCalculator("Subtract create 32-bit", medBg, imgDark);
subBg = getTitle();
selectWindow(medBg); close();     // Release background projection
selectWindow(imgDark); close();   // Release dark field image

// 6. Image math: divide to obtain transmittance (T), then close the subtracted images immediately
imageCalculator("Divide create 32-bit", subSample, subBg);
resultT = getTitle();
selectWindow(subSample); close(); // Release subtracted sample
selectWindow(subBg); close();     // Release subtracted background

// 7. Logarithmic transformation and physical quantity correction: A = -ln(T)
selectWindow(resultT);
run("Log");
run("Multiply...", "value=-1.000");

// Rename to the parent directory name
rename(parentDirName);

// 8. Adjust contrast before applying ROI and saving
resetMinAndMax();
run("Enhance Contrast", "saturated=0.35");

// 9. Save the full-size reconstructed image to the parent directory
saveAs("Tiff", saveDir + parentDirName + ".tif");

// 10. Apply the specified ROI and duplicate the region
makeRectangle(0, 1248, 2560, 400);
run("Duplicate...", "title=" + parentDirName + "_cut");

// 11. Save the duplicated (cut) image to the parent directory
saveAs("Tiff", saveDir + parentDirName + "_cut.tif");