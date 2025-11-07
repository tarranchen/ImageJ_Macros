// -------------------------------------------------------------
// Auto Background Correction Macro (Custom Grouped Divide Method)
// Author: Gemini / 根據用戶需求編寫 (已修正雙重名稱識別邏輯)
// -------------------------------------------------------------

// --- 參數設定 ---
initialGroupSize = 5; // 1-5 張扣背景 1
regularGroupSize = 10; // 6-15 扣背景 2, 16-25 扣背景 3, etc.
                
// -------------------------------------------------------------
// 1. 環境檢查與影像識別 (使用 ImageID)
// -------------------------------------------------------------
totalImages = nImages;
if (totalImages < 2)
    exit("? 錯誤：請先開啟兩個 Stack（一個背景、一個資料）。");

// 初始化變數
bgID = 0;
dataID = 0;
countBg = 0;
countData = 0;

// 遍歷所有開啟的影像，尋找切片數最多的 Data 和最少的 BG
for (i = 1; i <= totalImages; i++) {
    selectImage(i); // 按順序選取影像 ID
    currentID = getImageID;
    currentCount = nSlices;

    // 第一次疊代：先將第一個影像設為 Data，第二個影像設為 BG (初始比較基準)
    if (i == 1) {
        dataID = currentID;
        countData = currentCount;
    } else if (i == 2) {
        bgID = currentID;
        countBg = currentCount;
    }

    // 確保 dataID 始終指向切片數最多的影像
    if (currentCount > countData) {
        // 如果當前影像比目前的 Data 影像切片數還多
        // 則原 Data 變為 BG，當前影像為 Data
        bgID = dataID;
        countBg = countData;
        
        dataID = currentID;
        countData = currentCount;
    } 
    // 確保 bgID 始終指向切片數最少的影像 (且非 Data)
    else if (currentCount < countData && currentCount < countBg) {
        bgID = currentID;
        countBg = currentCount;
    }
}

// 最終檢查：確保我們找到了兩個不同的影像 ID
if (bgID == 0 || dataID == 0 || bgID == dataID)
    exit("? 錯誤：未能正確識別兩個 Stack，請確認開啟了兩個不同切片數的 Stack。");

// 取得影像名稱供輸出報告
selectImage(bgID);
bg = getTitle;
selectImage(dataID);
data = getTitle;

// 最終確認總切片數 (使用 ImageID 選取後讀取 nSlices)
selectImage(bgID);
totalSlicesBg = nSlices;
selectImage(dataID);
totalSlicesData = nSlices;

print("\\Clear");
print("--- 圖片角色確認 ---");
print("背景影像 (BG, 較少切片): " + bg + " (" + totalSlicesBg + " slices) [ID: " + bgID + "]"); 
print("資料影像 (DATA, 較多切片): " + data + " (" + totalSlicesData + " slices) [ID: " + dataID + "]"); 
print("--- 分組規則 ---");
print("第 1-5 張扣背景 1；之後每 10 張換一張背景。");

// -------------------------------------------------------------
// 2. 轉換為 32-bit (使用 ImageID)
// -------------------------------------------------------------
selectImage(bgID); // 使用 ID 選取
run("32-bit");
selectImage(dataID); // 使用 ID 選取
run("32-bit");

// -------------------------------------------------------------
// 3. 建立結果 Stack
// -------------------------------------------------------------
selectImage(dataID); // 以 Data Stack 維度為基礎
width = getWidth();
height = getHeight();

newImage("Result_Stack_Corrected", "32-bit black", width, height, 1); 
resultStackTitle = "Result_Stack_Corrected";
selectWindow(resultStackTitle);

// -------------------------------------------------------------
// 4. 主運算迴圈
// -------------------------------------------------------------
for (i = 1; i <= totalSlicesData; i++) {

    bgIndex = 1; // 預設使用背景 1
    
    // 修正分組邏輯 (前 5 張用 1，之後每 10 張一組)
    if (i > initialGroupSize) {
        // i=6: (6-5-1)/10 + 2 = 2
        bgIndex = floor((i - initialGroupSize - 1) / regularGroupSize) + 2;
    }
    
    // 確保背景索引不會超過背景 Stack 的總數
    if (bgIndex > totalSlicesBg) {
        bgIndex = totalSlicesBg;
    }
    
    // --- 準備資料切片 ---
    selectImage(dataID); // 使用 ID 選取 Data
    setSlice(i);
    run("Duplicate...", "title=dataTemp"); 

    // --- 準備背景切片 ---
    selectImage(bgID); // 使用 ID 選取 BG
    setSlice(bgIndex);
    run("Duplicate...", "title=bgTemp"); 

    // --- 執行扣背景 (Image Calculator - Divide) ---
    selectWindow("dataTemp");
    run("Image Calculator...", "image1=dataTemp image2=bgTemp operation=Divide 32-bit create"); 
    
    resultTitle = getTitle();

    // --- 將結果貼到總 Stack ---
    selectWindow(resultTitle);
    run("Copy"); 

    selectWindow(resultStackTitle);
    
    // 判斷：若非第一張切片，則新增一個切片
    if (i > 1) {
        run("Add Slice"); 
    }
    run("Paste"); 

    // --- 清理暫存視窗 ---
    selectWindow(resultTitle); close();
    selectWindow("bgTemp"); close();
    selectWindow("dataTemp"); close();

    print("? 完成第 " + i + " 張資料 (使用背景 " + bgIndex + ")");
}

// -------------------------------------------------------------
// 5. 完成
// -------------------------------------------------------------
selectWindow(resultStackTitle);
setSlice(1);
print("--- 處理完成 ---");
print("結果 Stack 名稱: " + resultStackTitle);
