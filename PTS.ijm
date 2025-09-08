// �\��G�N�@�Ӽv�����| (Stack) �����C�@�i���� (slice) �i�淥�y�Щβåd���y���ഫ�C
// �S��G����ɷ|�u�X��ܮ����ϥΪ̿���ഫ�Ҧ��C
// Install "Polar Transformer" plugin first: https://imagej.net/ij/plugins/polar-transformer.html

// --- ���ϥΪ̿���ഫ�Ҧ� ---
Dialog.create("Select Transform Mode");
Dialog.addChoice("Transform method:", newArray("Polar", "Cartesian"));
Dialog.show();

// **�ץ�**�G��� Dialog.getChoice() ������U�Կ�檺��ܡA
// �o�Ӥ�k�� Dialog.getString() ��M���B��í���C
transformMethod = Dialog.getChoice();

// --- �����l�v����T ---
originalID = getImageID();
sliceCount = nSlices();

// **�s�W**�G�ھڼv���e�װʺA�p�� Polar �Ҧ��� number �Ѽ�
selectImage(originalID); // �T�O��l�v���O�@�Τ�����
width = getWidth();
polarNumber = round(width * 3.1416);
polarCommand = "method=Polar degrees=360 default_center number=" + polarNumber;


// --- �B�z�޿� ---

// 1. �B�z�Ĥ@�i�����ëإ߷s���|
selectImage(originalID);
setSlice(1);

// �ĥ�í�����޿�A�����P�_��ܪ��Ҧ��C
if (transformMethod == "Polar") {
    run("Polar Transformer", polarCommand);
} else if (transformMethod == "Cartesian") {
    run("Polar Transformer", "method=Cartesian degrees=360 default_center");
} else {
    // �p�G���O�H�W��ؿ�� (�Ҧp�ϥΪ̫��U Cancel)�A�h�פ�{��
    exit("User cancelled the operation or an unknown error occurred. Macro terminated.");
}


// ���T�޲z�����G�O�U���ID�A�M�������{�ɪ�����
transformedSliceID = getImageID(); // �O�U�Ĥ@���ഫ���G�� ID
outputTitle = transformMethod + "_Transformed_Stack";
run("Duplicate...", "title=" + outputTitle); // ���D�אּ�q��
resultID = getImageID(); // ���o�s���|�� ID
selectImage(transformedSliceID); // ����^�{�ɪ�����
close(); // ������

// 2. �j��B�z�ѤU������ (�q�� 2 �i��̫�@�i)
if (sliceCount > 1) {
    for (i = 2; i <= sliceCount; i++) {
      selectImage(originalID);
      setSlice(i);
      
      // �P�˦a�A������������� run() ���O
      if (transformMethod == "Polar") {
          run("Polar Transformer", polarCommand);
      } else { // ���B�u�ݥ� else �Y�i�A�]���Ҧ��w�g�b�}�Y�T�w
          run("Polar Transformer", "method=Cartesian degrees=360 default_center");
      }
      
      run("Copy"); // �ƻs�ഫ���G
      close();     // �����{�ɲ��ͪ��ഫ����
      
      selectImage(resultID);
      run("Add Slice"); // �b���G���|���s�W�@�Ӥ���
      run("Paste");     // �N���G�K�W
    }
}

// �N��l�v���M���G�v������ܦb�e��
selectImage(originalID);
selectImage(resultID);

print("Task complete! Processed " + sliceCount + " slices using [" + transformMethod + "] mode.");

