setBatchMode(true); // 進入批次模式以提升速度
origID = getImageID();
getDimensions(width, height, channels, slices, frames);

// 1. 複製原始影像並處理成「層數標記」
run("Duplicate...", "title=Processing duplicate");
procID = getImageID();

for (z = 1; z <= slices; z++) {
    setSlice(z);
    // 將所有非零像素設為 1，零像素設為 0
    setThreshold(1, 65535); 
    run("Convert to Mask", "slice"); 
    run("Divide...", "value=255 slice"); // Mask 變為 0 或 1
    
    // 將該層數值乘以 z (第一層像素變為1, 第二層變為2...)
    run("Multiply...", "value=" + z + " slice");
}

// 2. 關鍵邏輯：
// 如果你要找「第一層」（最上層），我們需要從後往前塗色，或使用 Min Project
// 但最快的方式是：從最後一層掃到第一層，讓第一層的數值最後蓋上去
// 或者直接用 Max Project 找「最後一層」。

// 如果是要找「出現非零像素的最上面那一層 (Z 最小)」：
// 我們把 Z 軸反轉，然後取最大值
run("Reverse"); 
run("Z Project...", "projection=[Max Intensity]");
rename("First_NonZero_Z_Layer");

setBatchMode(false);
updateDisplay();
print("Done!");
