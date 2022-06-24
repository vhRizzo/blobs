clc;
clearvars;
imtool close all;
captionFontSize = 14;
%------------------------------------------------------------------------------------------------------------------------------------------------------
originalImage = imread('garrafa1.jpg');

thresholdValue = 125; % Limite de densidade de cores, selecione um valor de 0 a 255.

backForeComp = '<'; % Use '<' para objetos mais escuros que o fundo, e '>' para objetos mais claros que o fundo.
%------------------------------------------------------------------------------------------------------------------------------------------------------
% Verifica e converte para escala cinza.
[rows, columns, numberOfColorChannels] = size(originalImage);
if numberOfColorChannels > 1
	originalImageGray = rgb2gray(originalImage);
end
% Plota a imagem em escala cinza.
subplot(2, 3, 1);
imshow(originalImage);

% Maximiza a janela da imagem.
hFig1 = gcf;
hFig1.Units = 'normalized';
hFig1.WindowState = 'maximized'; % Vai para Tela Cheia.
hFig1.NumberTitle = 'off'; % Tira o titulo da janela (e.g. "Figure 1").
hFig1.Name = 'Identificacao de objetos'; % Substitui o titulo com esse texto.
drawnow;
caption = sprintf('Imagem original');
title(caption, 'FontSize', captionFontSize);
axis('on', 'image'); % Garante que a imagem nao esta artificialmente esticada por causa da proporcao da tela.

% Mostra o histograma para verificar a densidade de cinzas.
[pixelCount, grayLevels] = imhist(originalImageGray);
subplot(2, 3, 2);
bar(pixelCount);
title('Histograma imagem em escala cinza', 'FontSize', captionFontSize);
xlim([0 grayLevels(end)]);
grid on;
%------------------------------------------------------------------------------------------------------------------------------------------------------
% Gera uma imagem binaria a partir do limite predefinido.
if backForeComp == '<'
    binImage = originalImageGray < thresholdValue;
elseif backForeComp == '>'
    binImage = originalImageGray > thresholdValue;
end

% Preenche espaços separados da imagem utilizando discos de raio 25. Este
% valor pode ser ajustado caso esta funcao esteja 'preenchendo demais'.
S = strel('disk', 20);
binImage = imclose(binImage, S);
% Remove areas isoladas da imagem binaria com menos que 10000 pixels.
binImage = bwareaopen(binImage, 10000);
% Preenche os 'buracos' da imagem.
binImage = imfill(binImage, 'holes');

% Mostra o limite como uma linha vertical vermelha no histograma.
hold on;
maxYValue = ylim;
line([thresholdValue, thresholdValue], maxYValue, 'Color', 'r');
annotationText = sprintf('Limite em %d na escala cinza', thresholdValue);
text(double(thresholdValue + 5), double(0.5 * maxYValue(2)), annotationText, 'FontSize', 10, 'Color', [0 .5 0]);
if backForeComp == '<'
    text(double(thresholdValue - 70), double(0.94 * maxYValue(2)), 'Plano frontal', 'FontSize', 10, 'Color', [0 0 .5]);
    text(double(thresholdValue + 50), double(0.94 * maxYValue(2)), 'Plano de fundo', 'FontSize', 10, 'Color', [0 0 .5]);
elseif backForeComp == '>'
    text(double(thresholdValue - 70), double(0.94 * maxYValue(2)), 'Plano de fundo', 'FontSize', 10, 'Color', [0 0 .5]);
    text(double(thresholdValue + 50), double(0.94 * maxYValue(2)), 'Plano frontal', 'FontSize', 10, 'Color', [0 0 .5]);
end

% Plota a imgem binaria.
subplot(2, 3, 3);
imshow(binImage);
title('Imagem binária após filtragem', 'FontSize', captionFontSize);
%------------------------------------------------------------------------------------------------------------------------------------------------------
% Identifica objetos individuais verificando se possuem pixels conectados,
% dando um rotulo, nesse caso um numero, para cada objeto.
[labeledImage, numberOfBlobs] = bwlabel(binImage);

% Da uma cor aleatoria para cada objeto.
coloredLabels = label2rgb (labeledImage, 'hsv', 'k', 'shuffle');
subplot(2, 3, 4);
imshow(coloredLabels);
axis image;
caption = sprintf('Objetos rotulados');
title(caption, 'FontSize', captionFontSize);

% Obtem a area (quantidade de pixels) da imagem binaria e o centroide de cada objeto.
props = regionprops(labeledImage, originalImageGray, 'Centroid', 'Area');
%------------------------------------------------------------------------------------------------------------------------------------------------------
% Plota as bordas utilizando as coordenada retornadas por bwboundaries(),
% que retorna um array de celulas, onde cada celula contem a linha/coluna
% de um objeto na imagem.
subplot(2, 3, 5);
imshow(originalImage);
title('Imagem original com as bordas do filtro', 'FontSize', captionFontSize);
axis('on', 'image');

boundaries = bwboundaries(binImage);
% Em cada celula tem uma lista de coordenadas N por 2 em formato (linha,
% coluna), não confundir com (x, y).
% A coluna 1 tem a coordenada da linha, ou y. E a coluna 2 de x.
numberOfBoundaries = size(boundaries, 1); % Conta a quantidade de bordas pro loop.

% Efetivamente plota as bordas.
hold on;
for k = 1 : numberOfBoundaries
	thisBoundary = boundaries{k};
	x = thisBoundary(:,2);
	y = thisBoundary(:,1);
	plot(x, y, 'r-', 'LineWidth', 2);
end
hold off;
%------------------------------------------------------------------------------------------------------------------------------------------------------
% De modo semelhante as bordas, o mesmo e feito para as centroides dos
% objetos, utilizado somente para rotular graficamente os objetos na
% imagem, onde seus rotulos sao inseridos em suas centroides.
allBlobCentroids = vertcat(props.Centroid);
centroidsX = allBlobCentroids(:, 1);
centroidsY = allBlobCentroids(:, 2);

subplot(2, 3, 4);
for k = 1 : numberOfBlobs           % Loop through all blobs.
	% Place the blob label number at the centroid of the blob.
	text(centroidsX(k), centroidsY(k), num2str(k), 'FontSize', captionFontSize, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
end
%------------------------------------------------------------------------------------------------------------------------------------------------------
% Plota a imagem original com o filtro aplicado.
subplot(2, 3, 6);
filteredImage = originalImage .* uint8(binImage);
imshow(filteredImage);
title('Imagem original com o filtro aplicado', 'FontSize', captionFontSize);
axis('on', 'image');

Volume = props.Area/55;
