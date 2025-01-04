% % Sumayya
% dentate = load('/Users/ozzy/Desktop/ses2/Dentate_161224_000.mat');
% dentateSham0w = load('/Users/ozzy/Desktop/ses2/DentateSham0w_161224_000.mat');
% dentateSham30w = load('/Users/ozzy/Desktop/ses2/DentateSham302_161224_000.mat');
% lobule5 = load('/Users/ozzy/Desktop/ses2/Lobule5_161224_000.mat');
% lobule8 = load('/Users/ozzy/Desktop/ses2/Lobule8_161224_000.mat');
% V1 = load('/Users/ozzy/Desktop/ses2/V1_161224_000.mat');
% baseline = load('/Users/ozzy/Desktop/ses2/X_161224_000.mat');

% NK
dentate = load('/Users/ozzy/Desktop/HERO_03dat/DN_030125_000.mat');
dentateSham0w = load('/Users/ozzy/Desktop/HERO_03dat/DN_0w_030125_000.mat');
dentateSham30w = load('/Users/ozzy/Desktop/HERO_03dat/Dn_30wflip_030125_000.mat');
lobule5 = load('/Users/ozzy/Desktop/HERO_03dat/L5_030125_000.mat');
lobule8 = load('/Users/ozzy/Desktop/HERO_03dat/L8_take2_030125_000.mat');
V1 = load('/Users/ozzy/Desktop/HERO_03dat/V1_030125_000.mat');
baseline = load('/Users/ozzy/Desktop/HERO_03dat/V1_030125_000.mat');

% % SMY
% data = {baseline, dentate, lobule5, lobule8, V1, dentateSham0w, dentateSham30w};
% labels = {'Nobaseline','dentate','lobule5','lobule8','V1sham','sham0w','sham30w'};
% allPeaks =[];

%Nika
data = {dentate, lobule5, lobule8, V1, dentateSham0w, dentateSham30w};
labels = {'dentate','lobule5','lobule8','V1sham','sham0w','sham30w'};
allPeaks =[];

for ii = 1:length(data)
    fields = fieldnames(data{ii});
    dataset = data{ii}.(fields{2});
    peaks = peak2peak(reshape(dataset.values(2800:end,1,:), [], 15));
    allPeaks = [allPeaks peaks'];
end

boxplot(allPeaks, labels)

% x = [allPeaks(:,1) + allPeaks(:,6) + allPeaks(:,7)] ./ 3;
% allPeaks = allPeaks(:,1:5);
% allPeaks(:,1) = x;
% figure
% boxplot(allPeaks, {'baseline','dentate','lobule5','lobule8','V1sham'})
