// 功能：將一個影像堆疊 (Stack) 中的每一張切片 (slice) 進行極座標或笛卡爾座標轉換。
// 特色：執行時會彈出對話框讓使用者選擇轉換模式。
// Install "Polar Transformer" plugin first: https://imagej.net/ij/plugins/polar-transformer.html

// --- 讓使用者選擇轉換模式 ---
Dialog.create("Select Transform Mode");
Dialog.addChoice("Transform method:", newArray("Polar", "Cartesian"));
Dialog.show();

// **修正**：改用 Dialog.getChoice() 來獲取下拉選單的選擇，
// 這個方法比 Dialog.getString() 更專門且更穩健。
transformMethod = Dialog.getChoice();

// --- 獲取原始影像資訊 ---
originalID = getImageID();
sliceCount = nSlices();

// **新增**：根據影像寬度動態計算 Polar 模式的 number 參數
selectImage(originalID); // 確保原始影像是作用中視窗
width = getWidth();
polarNumber = round(width * 3.1416);
polarCommand = "method=Polar degrees=360 default_center number=" + polarNumber;


// --- 處理邏輯 ---

// 1. 處理第一張切片並建立新堆疊
selectImage(originalID);
setSlice(1);

// 採用穩健的邏輯，直接判斷選擇的模式。
if (transformMethod == "Polar") {
    run("Polar Transformer", polarCommand);
} else if (transformMethod == "Cartesian") {
    run("Polar Transformer", "method=Cartesian degrees=360 default_center");
} else {
    // 如果不是以上兩種選擇 (例如使用者按下 Cancel)，則終止程式
    exit("User cancelled the operation or an unknown error occurred. Macro terminated.");
}


// 正確管理視窗：記下兩個ID，然後關閉臨時的那個
transformedSliceID = getImageID(); // 記下第一個轉換結果的 ID
outputTitle = transformMethod + "_Transformed_Stack";
run("Duplicate...", "title=" + outputTitle); // 標題改為通用
resultID = getImageID(); // 取得新堆疊的 ID
selectImage(transformedSliceID); // 選取回臨時的視窗
close(); // 關閉它

// 2. 迴圈處理剩下的切片 (從第 2 張到最後一張)
if (sliceCount > 1) {
    for (i = 2; i <= sliceCount; i++) {
      selectImage(originalID);
      setSlice(i);
      
      // 同樣地，直接執行對應的 run() 指令
      if (transformMethod == "Polar") {
          run("Polar Transformer", polarCommand);
      } else { // 此處只需用 else 即可，因為模式已經在開頭確定
          run("Polar Transformer", "method=Cartesian degrees=360 default_center");
      }
      
      run("Copy"); // 複製轉換結果
      close();     // 關閉臨時產生的轉換視窗
      
      selectImage(resultID);
      run("Add Slice"); // 在結果堆疊中新增一個切片
      run("Paste");     // 將結果貼上
    }
}

// 將原始影像和結果影像都顯示在前景
selectImage(originalID);
selectImage(resultID);

print("Task complete! Processed " + sliceCount + " slices using [" + transformMethod + "] mode.");

