
clear all; clc; 

Fnum = length(dir);
Flist = dir; 
Porder = 0;
OutcomeFile = "FontsDataOutcome.xlsx" ; 

for a = 1:Fnum
    FindN = struct2cell(Flist(a));
    Fname = FindN{1};                 
    FA = strfind(Fname, 'png');
    
    %__________________ 분석 시작 __________________
    
    if FA ~= 0
        
        
        Porder = Porder +1;
        disp(Porder);
        
        FileNameLength = length(Fname);
        FontName = Fname(1:FileNameLength-4);
        
        % 네모틀1 탈네모틀0 세리프1 산세리프0
        % 네+세 11, 네+산 10, 탈+세 01, 탈+산 00
         
        execute = ['processed', num2str(Porder), ' = IntGabor(Fname, Porder);'] ;
        eval(execute) ; 
        
        
        
    end
    
end

IndexInst = {' 폰트명 ', '네모/탈네모', '세리프/산세',...
    'Sobel_Sum',...
    'Harris_Count', 'Harris_MetAvg', 'Harris_MetSd',...
    'Brisk_Count', 'Brisk_MetAvg', 'Brisk_MetSd', ...
    'Mser_Count', 'Mser_OriAvg', 'Mser_OriSd', 'Mser_size' } ;

writecell(IndexInst, OutcomeFile, 'Sheet', 1, 'Range', strcat('A1'));

disp("All Finished!!") ;
        


function processed = IntGabor(FontFileName, order)

processed.font = FontFileName ; 

%%___ Step1 그레이스케일 변환 
img = imread(FontFileName);
Gimg = rgb2gray(img);

 %%___ Step2 Gabor filter 
 
 % [  Parameters  ] 
 % Bandwidth = 1
 % gamma = aspect ratio 0.5
 % psi = phase shift 0
 % lambda = wavelength >=2
 % theta = Orientation: angle  0 ~ 180
 
 lambda = 2; OriN = 16; thetaList = []; 
 for i = [1:OriN] 
     thetaList(i) = 180*(i/OriN);
 end
 % 방향을 16가지로 하여 Gabor Filter Bank를 형성  
 
gaborArray = gabor(lambda, thetaList);
gaborMag = imgaborfilt(Gimg, gaborArray);

% 16방향 Gabor Bank를 L2-norm 방식으로 Superpositioning
Filtered_img = sum(abs(gaborMag).^2, 3).^0.5;
% Normalized 
Filtered_img = Filtered_img./max(Filtered_img(:));

% L2 Norm : '벡터 내 모든 원소의 절댓값 제곱의 합'의 제곱근.
% ||x||2 = sqrt(a^2 + b^2 + c^2 + d^2)
% 특정 벡터가 2차원 상에서 가지는 크기를 의미. 


% """    Features Detection   """

Sobel_Data = edge(Filtered_img, 'Sobel'); % Sobel Edge Detection
% figure;
% imshow(Sobel_Data);
% title('Sobel');

Brisk_Data = detectBRISKFeatures(Filtered_img); % BRISK Keypoints Detection
% figure;
% imshow(Filtered_img); hold on;
% plot(Brisk_Data.selectStrongest(50));
% title('BRISK');

Harris_Data = detectHarrisFeatures(Filtered_img); % Harris corner detection
% figure;
% imshow(Filtered_img); hold on;
% plot(Harris_Data.selectStrongest(50));
% title('Harris');

MSER_Data = detectMSERFeatures(Filtered_img); % MSER Blob detection
% figure; imshow(Filtered_img); hold on;
% plot(MSER_Data,'showPixelList',true,'showEllipses',false);
% title('MSER');

% 데이터 정리

Sobel_Sum = sum(Sobel_Data,'all') ; % 처리된 이미지 배열의 평균값
%Sobel_Sd = std(Sobel_Data,0,'all') ; % 처리된 이미지 배열의 표준편차값

Harris_Count = Harris_Data.Count ;
Harris_MetAvg = mean(Harris_Data.Metric, 'all') ;
Harris_MetSd = std(Harris_Data.Metric,0,'all') ;

Brisk_Count = Brisk_Data.Count ;
Brisk_MetAvg = mean(Brisk_Data.Metric, 'all') ;
Brisk_MetSd = std(Brisk_Data.Metric,0,'all') ;

Mser_Count = MSER_Data.Count;
Mser_OriAvg = mean(MSER_Data.Orientation,'all') ;
Mser_OriSd = std(MSER_Data.Orientation,0,'all') ;

Mser_size = 0 ;
for k = 1 : Mser_Count
    Mser_size = Mser_size + size(MSER_Data.PixelList(k), 1) ;
end

FontType1 = FontFileName(1);
FontType2 = FontFileName(2);

OutDataBox = {FontFileName, FontType1, FontType2, ...
    Sobel_Sum,  ...
    Harris_Count, Harris_MetAvg, Harris_MetSd,...
    Brisk_Count, Brisk_MetAvg, Brisk_MetSd ...
    Mser_Count, Mser_OriAvg, Mser_OriSd, Mser_size } ;

Sobel_set.Sobel_data = Sobel_Data ; 
Sobel_set.Sobel_sum = Sobel_Sum ; 

Harris_set.Harris_data = Harris_Data ; 
Harris_set.MetAvg = Harris_MetAvg ; 
Harris_set.MetSd = Harris_MetSd ;

Brisk_set.Brisk_data = Brisk_Data ; 
Brisk_set.MetAvg = Brisk_MetAvg ;
Brisk_set.MetSd = Brisk_MetSd ;

Mser_set.Mser_data = MSER_Data ;
Mser_set.OriAvg = Mser_OriAvg ; 
Mser_set.OriSd = Mser_OriSd ; 
Mser_set.size = Mser_size ; 

processed.Sobel = Sobel_set ; 
processed.Brisk = Brisk_set ;
processed.Harris = Harris_set ;
processed.MSER = Mser_set ;

OutcomeFile = "FontsDataOutcome.xlsx" ; 
writecell(OutDataBox, OutcomeFile, 'Sheet', 1, 'Range', strcat('A', num2str(order+1)));

end



