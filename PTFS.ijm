/*

@name Process, Recombine, Convert, and Transform Stack (Final Custom Version with Debug)

@description

對一個堆疊中的每張圖片進行：

a. 逆時針旋轉90度

b. 分割成左右兩半

c. 對左半邊影像進行上下+左右翻轉

d. 將處理後的左半邊拼接在右半邊下方

收集所有結果到新的 32-bit 堆疊

使用百分位數裁切法，最佳化動態範圍後，轉換為 16-bit (保留此堆疊)

對 16-bit 堆疊中的每一個切片進行極座標轉換

將所有轉換結果收集到名為 "C_Stack" 的最終堆疊中
*/

macro "Process, Recombine, Convert, and Transform Stack - Final Custom Debug" {
// --- Part 1: Recombine Slices (32-bit) ---
originalID = getImageID();
sliceCount = nSlices();
if (sliceCount < 1) exit("錯誤：需要一個影像堆疊 (stack)。");

type = "32-bit black";
setBatchMode(true);
recombinedID = -1; // 初始化堆疊ID變數
cStackID = -1; // 初始化C_Stack ID變數

print("開始處理 " + sliceCount + " 個切片...");

for (i = 1; i <= sliceCount; i++) {
    print("處理切片 " + i + "/" + sliceCount);
    
    selectImage(originalID);
    setSlice(i);
    run("Duplicate...", "title=temp_slice");

    run("Rotate 90 Degrees Left");
    rotatedWidth = getWidth();
    rotatedHeight = getHeight();

    // 計算精確的半寬
    leftWidth = floor(rotatedWidth/2);
    rightWidth = rotatedWidth - leftWidth;
    
    //print("  原始寬度: " + rotatedWidth);
    //print("  左半邊寬度: " + leftWidth);
    //print("  右半邊寬度: " + rightWidth);

    // 分割右半邊
    makeRectangle(leftWidth, 0, rightWidth, rotatedHeight);
    run("Duplicate...", "title=right_half");
    
    selectWindow("temp_slice");
    // 分割左半邊
    makeRectangle(0, 0, leftWidth, rotatedHeight);
    run("Duplicate...", "title=left_half");
    
    close("temp_slice");

    // 對左半邊進行翻轉
    selectWindow("left_half");
    run("Flip Vertically"); 
    run("Flip Horizontally");

    selectWindow("right_half");
    rightActualWidth = getWidth();
    rightActualHeight = getHeight();

    selectWindow("left_half");
    leftActualWidth = getWidth();
    leftActualHeight = getHeight();

    // 使用較大的寬度作為最終寬度
    if (leftActualWidth >= rightActualWidth) {
        finalWidth = leftActualWidth;
    } else {
        finalWidth = rightActualWidth;
    }

    // 建立新的合併影像
    newImage("processed_slice", type, finalWidth, leftActualHeight + rightActualHeight, 1);

    // 貼上右半邊（上方）
    selectWindow("right_half");
    run("Select All"); run("Copy");
    selectWindow("processed_slice");
    makeRectangle(0, 0, rightActualWidth, rightActualHeight); 
    run("Paste");

    // 貼上左半邊（下方）
    selectWindow("left_half");
    run("Select All"); run("Copy");
    selectWindow("processed_slice");
    makeRectangle(0, rightActualHeight, leftActualWidth, leftActualHeight); 
    run("Paste");

    close("right_half");
    close("left_half");

    if (i == 1) {
        rename("Recombined_Stack");
        recombinedID = getImageID(); // 儲存影像ID
        //print("  建立 Recombined_Stack，ID: " + recombinedID);
    } else {
        // 確保之前的堆疊仍然存在
        //print("  檢查 recombinedID: " + recombinedID + ", 是否存在: " + isOpen(recombinedID));
        if (isOpen(recombinedID)) {
            // 使用更直接的方法合併堆疊
            currentProcessedID = getImageID(); // processed_slice的ID
            
            // 將processed_slice複製為切片並添加到現有堆疊
            run("Select All");
            run("Copy");
            
            selectImage(recombinedID);
            run("Add Slice");
            run("Paste");
            
            // 清理臨時影像
            selectImage(currentProcessedID);
            close();
            
            //print("  添加切片到 Recombined_Stack");
        } else {
            print("錯誤: Recombined_Stack 已遺失，重新建立...");
            rename("Recombined_Stack");
            recombinedID = getImageID();
            print("  重新建立 Recombined_Stack，新ID: " + recombinedID);
        }
    }
}

print("完成所有切片的重組處理");

// --- Part 2: Optimize and Convert to 16-bit ---
print("開始動態範圍最佳化...");

// 確保Recombined_Stack存在
if (isOpen(recombinedID)) {
    selectImage(recombinedID);
} else {
    exit("錯誤: Recombined_Stack 遺失，無法繼續處理");
}

getStatistics(nPixels, mean, min, max, std, histogram);
print("統計資訊 - 像素數: " + nPixels + ", 平均: " + mean + ", 最小: " + min + ", 最大: " + max);

lowerPercentile = 0.003; 
upperPercentile = 0.997;
lowerCutoff = nPixels * lowerPercentile;
upperCutoff = nPixels * upperPercentile;

cumulativeCount = 0;
for (i = 0; i < 256; i++) {
    cumulativeCount += histogram[i];
    if (cumulativeCount >= lowerCutoff) {
        newMin = min + i * ((max - min) / 256.0);
        break;
    }
}

cumulativeCount = 0;
for (i = 0; i < 256; i++) {
    cumulativeCount += histogram[i];
    if (cumulativeCount >= upperCutoff) {
        newMax = min + i * ((max - min) / 256.0);
        break;
    }
}

print("裁切後 (0.3% - 99.7%) 的新範圍：newMin = " + newMin + ", newMax = " + newMax);
setMinAndMax(newMin, newMax);
run("16-bit");
print("轉換為 16-bit 完成");

// 更新recombinedID，因為類型轉換可能會改變ID
recombinedID = getImageID();
//print("更新 Recombined_Stack ID: " + recombinedID);

// 立即顯示並保存 Recombined_Stack
setBatchMode(false);  // 暫時關閉批次模式以顯示影像
selectImage(recombinedID);

// 確保影像有正確的標題
if (getTitle() != "Recombined_Stack") {
    rename("Recombined_Stack");
}

//print("Recombined_Stack (16-bit) 立即顯示完成");

// 可選：保存 Recombined_Stack（如需要，請取消註解下一行）
// saveAs("Tiff", getDirectory("home") + "Recombined_Stack_16bit.tif");

setBatchMode(true);   // 重新開啟批次模式繼續處理

// --- Part 3: Apply Polar Transform (Robust Stack Creation) ---
print("開始進行極座標轉換...");

if (isOpen(recombinedID)) {
    selectImage(recombinedID);
    sourceSliceCount = nSlices();
    //print("來源堆疊有 " + sourceSliceCount + " 個切片");
} else {
    exit("錯誤: Recombined_Stack 遺失，無法進行極座標轉換");
}

if (sourceSliceCount < 1) {
    print("來源堆疊為空，跳過極座標轉換。");
    cStackID = -1; // 標記為無C_Stack
} else {
    // 處理第一個切片以建立 C_Stack
    print("處理第 1 個切片進行極座標轉換...");
    selectImage(recombinedID);
    setSlice(1);
    run("Duplicate...", "title=temp_for_transform");
    
    run("Polar Transformer", "method=Cartesian degrees=360 default_center");
    
    close("temp_for_transform");
    rename("C_Stack");
    cStackID = getImageID(); // 儲存C_Stack的ID
    //print("  建立 C_Stack，ID: " + cStackID);

    // 處理剩餘的切片並將它們附加到 C_Stack
    for (j = 2; j <= sourceSliceCount; j++) {
        print("處理第 " + j + " 個切片進行極座標轉換...");
        selectImage(recombinedID);
        setSlice(j);
        run("Duplicate...", "title=temp_for_transform");
        
        run("Polar Transformer", "method=Cartesian degrees=360 default_center");
        
        transformedID = getImageID();
        close("temp_for_transform");
        
        // 使用Add Slice方法而不是Concatenate
        run("Select All");
        run("Copy");
        
        selectImage(cStackID);
        run("Add Slice");
        run("Paste");
        
        selectImage(transformedID);
        close();
        
        //print("  添加到 C_Stack");
    }
}

print("極座標轉換完成");

// --- Part 4: Finalization ---
setBatchMode(false);

// 確保所有影像都可見
//print("顯示最終結果...");

// 檢查並顯示 Recombined_Stack
//print("檢查 Recombined_Stack ID: " + recombinedID);
if (recombinedID > 0 && isOpen(recombinedID)) {
    selectImage(recombinedID);
    // 確保影像有正確的標題
    if (getTitle() != "Recombined_Stack") {
        rename("Recombined_Stack");
    }
    //print("Recombined_Stack (16-bit) 已建立並顯示");
} else {
    // 嘗試通過標題找到影像
    if (isOpen("Recombined_Stack")) {
        selectWindow("Recombined_Stack");
        //print("Recombined_Stack (16-bit) 通過標題找到並顯示");
    } else {
        print("警告: Recombined_Stack 無法顯示");
    }
}

// 檢查並顯示 C_Stack
//print("檢查 C_Stack ID: " + cStackID);
if (cStackID > 0 && isOpen(cStackID)) {
    selectImage(cStackID);
    // 確保影像有正確的標題
    if (getTitle() != "C_Stack") {
        rename("C_Stack");
    }
    //print("C_Stack (極座標轉換) 已建立並顯示");
} else {
    // 嘗試通過標題找到影像
    if (isOpen("C_Stack")) {
        selectWindow("C_Stack");
        //print("C_Stack (極座標轉換) 通過標題找到並顯示");
    } else {
        print("警告: C_Stack 無法顯示");
    }
}

if (roiManager("count") > 0) roiManager("reset");
if (isOpen("ROI Manager")) {
    selectWindow("ROI Manager");
    run("Close");
}

print("=== 巨集完成！===");
print("已建立 'Recombined_Stack' (16-bit) 和 'C_Stack' (極座標轉換)。");
}