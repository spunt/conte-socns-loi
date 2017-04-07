clear all
% | Scale
sc = imread('scalegerman.jpg');
sc = imresize(sc, [900 1200]);
fn = files('*_*jpg');
for i = 1:length(fn)
    im = imread(fn{i});
    sc(1:750,:,:) = im(1:750,:,:);
    imwrite(sc, fn{i}, 'jpg');
end









