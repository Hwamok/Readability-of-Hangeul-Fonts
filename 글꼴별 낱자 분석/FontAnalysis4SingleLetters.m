clear all; clc; 

% 테스트 : 연구실
cd('C:\Users\Hwamok\Desktop\Mok_proj\Font_Project\font_single\test') ; 
% Target : 연구실
cd("C:\Users\Hwamok\Desktop\Mok_proj\Font_Project\font_single\img_save") ; 

file_nb = length(dir);
file_list = dir; 
file_order = 0;

font_order = 0 ; 
for a = 1 : file_nb
    find_file = struct2cell(file_list(a));
    file_name = find_file{1};                 
    target_file = strfind(file_name, 'png');
    
    %__________________분석 시작_________________________________
    
    if target_file ~= 0
        
        file_order = file_order +1;
        if rem(file_order, 6) == 1 
            font_order = font_order + 1 ; 
        end
        sub_order = file_name(end-5) ; 
        
        % 네모틀1 탈네모틀0 세리프1 산세리프0
        % 네+세 11, 네+산 10, 탈+세 01, 탈+산 00
         
        %% 1차 분석 : 일단 모든 글꼴파일 분석 
        execute1 = ['processed', num2str(font_order), '_', num2str(sub_order), ' = font_analysis1(file_name, file_order);'] ;
        eval(execute1) ; 
            
    end
end

%% 2차 분석 : 글꼴별로 낱자 분석 결과 취합하여 엑셀 파일에 작성.
OutcomeFile = "FontAnalysis_results_renew.xlsx" ;

%_Ready excel file__________________________________________________________________
IndexInst = {'글꼴명', '글꼴종류', '글꼴코드', '글자 크기', '가로/세로', '자간', '반듯함', '굵기', '시각적 복잡성'} ;
writecell(IndexInst, OutcomeFile, 'Sheet', 1, 'Range', strcat('A1'));
%_______________________________________________________________________________

for b = 1 : font_order
    for c = 1 : 6
        execute2 = ['var', num2str(c), ' = processed', num2str(b), '_', num2str(c), ' ;'] ;
        eval(execute2) ;
    end
    
    execute3 = ['Results', num2str(b), ' = font_analysis2(b, OutcomeFile, var1, var2, var3, var4, var5, var6) ;'] ;
    eval(execute3) ;
    
    
end

disp("All Finished!!") ;
        
function processed = font_analysis1(file_name, file_order)

disp("----" + file_order + "번째 font---------");

font_name = file_name(3 : end-4);
disp("   " + font_name + " 분석") ; 

font_type_list = ["탈네모/산세리프", "탈네모/세리프", "네모/산세리프", "네모/세리프"] ; 
font_type = font_type_list(bin2dec( file_name(1: 2) ) +1) ; 
disp("   " + font_type ) ; 

processed.name = font_name ; 
processed.type = font_type ; 
processed.type_code = file_name(1:2) ; 

img = imread(file_name);

% """    Features Detection   """
% _______________________________________________________
% (1) 글자크기 : w x h
% (2) 가로세로 비율 : w / h
% (3) 굵기 : 글꼴 면적
% (4) 자간 : 전체 면적 - 글꼴 면적 
% (5) 시각적 복잡성 : Brisk keypoint 
% (6) 반듯함 : w x h s.d.
% _______________________________________________________

%% (1) 글자크기 w x h  , (2) 가로세로 비율 w / h 
img_size = size(img) ; 
 
x1 = img_size(2) ; x2 = 0 ;
y1 = img_size(1) ; y2 = 0 ; 

% 열 검색 x 좌표
for i = 1 : img_size(1) 
    search_col = img(i,:) ; 
    non_zero = find(search_col > 0) ;
    
    if length(non_zero) ~= 0 
        first_non_zero = non_zero(1) ; 
        last_non_zero = non_zero(end) ;

        if x1 > first_non_zero 
            x1 = first_non_zero ; 
        end
        if x2 < last_non_zero 
            x2 = last_non_zero ;
        end
    end
    
end

% 행 검색 y 좌표
for i = 1 : img_size(2) 
    search_row = img(:,i) ; 
    non_zero = find(search_row > 0) ;
    
      if length(non_zero) ~= 0 
        first_non_zero = non_zero(1) ; 
        last_non_zero = non_zero(end) ;

        if y1 > first_non_zero 
            y1 = first_non_zero ; 
        end
        if y2 < last_non_zero 
            y2 = last_non_zero ;
        end
    end
    
end

w = x2 - x1 ; % width
h = y2 - y1 ; % height

font_size = w * h ; 
font_ratio = w / h ; 

processed.size = font_size ; 
processed.ratio = font_ratio ; 

disp("* 글꼴 크기 : " + w + " x " + h + " = " + font_size) ; 
disp("* 글꼴 가로/세로 비율 : " + w + " / " + h + " = " + font_ratio) ;
 
% % 글자 box 시각화 
% Nemo = [x1, y1, w, h] ; 
% figure ;
% imshow(img) ; hold on ; 
% rectangle('Position', Nemo, 'EdgeColor', 'r') ;

%% (3) 굵기 : 글꼴 면적 & (4) 자간 : 전체 면적 - 글꼴 면적
font_area_array = img( find( img > 0) ) ; 
font_area = length(font_area_array) ; 
disp("* 글꼴 굵기(글꼴 면적) : " + font_area) ;

img_size = size(img) ; 
font_letterspace = (img_size(1) * img_size(2)) - font_area ; 
disp("* 자간 : " + font_letterspace) ; 

processed.area = font_area ; 
processed.letterspace = font_letterspace ;

%% (5) 시각적 복잡성 : Brisk keypoint 

 %%___ Step2 Gabor filter 
 
 % [  Parameters  ] 
 % Bandwidth = 1
 % gamma = aspect ratio 0.5
 % psi = phase shift 0
 % lambda = wavelength >=2
 % theta = Orientation: angle  0 ~ 180
 
 lambda = 2; Ori_nb = 16; thetaList = []; 
 for i = [1:Ori_nb] 
     thetaList(i) = 180*(i/Ori_nb);
 end
 % 방향을 12가지로 하여 Gabor Filter Bank를 형성  
 
gaborArray = gabor(lambda, thetaList);
gaborMag = imgaborfilt(img, gaborArray);

% 12방향 Gabor Bank를 L2-norm 방식으로 Superpositioning
Filtered_img = sum(abs(gaborMag).^2, 3).^0.5;
% Normalized 
Filtered_img = Filtered_img./max(Filtered_img(:));

% L2 Norm : '벡터 내 모든 원소의 절댓값 제곱의 합'의 제곱근.
% ||x||2 = sqrt(a^2 + b^2 + c^2 + d^2)
% 특정 벡터가 2차원 상에서 가지는 크기를 의미. 

Brisk_Data = detectBRISKFeatures(Filtered_img); % BRISK Keypoints Detection
% figure;
% imshow(Filtered_img); hold on;
%plot(Brisk_Data.selectStrongest(50));
% title('BRISK');

Brisk_Count = Brisk_Data.Count ;
Brisk_MetAvg = mean(Brisk_Data.Metric, 'all') ;
Brisk_MetSd = std(Brisk_Data.Metric,0,'all') ;

processed.Brisk.raw = Brisk_Data ;
processed.Brisk.count = Brisk_Count ;
processed.Brisk.MetAvg = Brisk_MetAvg ;
processed.Brisk.MetSd = Brisk_MetSd ; 

Harris_Data = detectHarrisFeatures(Filtered_img); % Harris corner detection
% figure;
% imshow(Filtered_img); hold on;
% plot(Harris_Data.selectStrongest(50));
% title('Harris');

processed.Harris = Harris_Data ; 

disp("* Brisk point 수 : " + Brisk_Count) ; 
disp("----" + file_order + "번째 font 끝--------");
disp("     ") ; 

end

function Results = font_analysis2(font_order, OutcomeFile, var1, var2, var3, var4, var5, var6) 
    
    Results.name = var1.name(1:end-4) ; 
    disp("______" + Results.name + "2차 분석______") ;
    
    Results.type = var1.type ;
    Results.type_code = var1.type_code ; 
    
    size_list = [var1.size, var2.size, var3.size, var4.size, var5.size, var6.size] ;
    Results.size = mean(size_list) ; 
    Results.size_sd = std(size_list) ; 
    
    ratio_list = [var1.ratio, var2.ratio, var3.ratio, var4.ratio, var5.ratio, var6.ratio] ;
    Results.ratio = mean(ratio_list) ; 
    
    area_list = [var1.area, var2.area, var3.area, var4.area, var5.area, var6.area] ;
    Results.area = mean(area_list) ;
    
    letterspace_list = [var1.letterspace, var2.letterspace, var3.letterspace, var4.letterspace, var5.letterspace, var6.letterspace] ;
    Results.letterspace = mean(letterspace_list) ;
    
    Brisk_list = [var1.Brisk.count, var2.Brisk.count, var3.Brisk.count, var4.Brisk.count, var5.Brisk.count, var6.Brisk.count] ;
    Results.Brisk_count = mean(Brisk_list) ; 
    
    disp("* 글자 크기 : " + Results.size) ; 
    disp("* 가로/세로 비율 : " + Results.ratio) ;
    disp("* 반듯함 : " + Results.size_sd) ;
    disp("* 굵기 : " + Results.area) ; 
    disp("* 자간 : " + Results.letterspace) ; 
    disp("* 시각적 복잡성 : " + Results.Brisk_count) ; 
    
    % 엑셀 파일에 작성 
    % IndexInst = {'글꼴명', '글꼴종류', '글꼴코드', '글자 크기', '가로/세로', '자간', '반듯함', '굵기', '시각적 복잡성'} ;
    result_box = { Results.name, Results.type, Results.type_code, Results.size, Results.ratio, Results.letterspace,...
                        Results.size_sd, Results.area, Results.Brisk_count } ; 
                    
    writecell(result_box, OutcomeFile, 'Sheet', 1, 'Range', strcat('A', num2str(font_order+1))) ;
    disp("__________________________") ;
    disp("               ") ;
    
    
end

