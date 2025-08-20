/*
    Copyright (C) 2025 roundedrectangle, 2020 Slava Monich et al.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include "lottieioplugin.h"

const QByteArray LottieIOPlugin::LottieIOHandler::NAME("json");

LottieIOPlugin::LottieIOHandler::LottieIOHandler(QIODevice* device, const QByteArray& format) :
    frameRate(0.),
    frameCount(0),
    currentFrame(0)
{
    QFileDevice* file = qobject_cast<QFileDevice*>(device);
    if (file)
        fileName = QFileInfo(file->fileName()).fileName();

    setDevice(device);
    setFormat(format);
}

LottieIOPlugin::LottieIOHandler::~LottieIOHandler() {
    if (currentRender.valid())
        currentRender.get();
}

bool LottieIOPlugin::LottieIOHandler::load() {
    if (!animation && device()) {
        ByteArray json(device()->readAll());
        if (json.size() > 0) {
            animation = rlottie::Animation::loadFromData(json, std::string(), std::string(), false);
            if (animation) {
                size_t width, height;
                animation->size(width, height);
                frameRate = animation->frameRate();
                frameCount = (int) animation->totalFrame();
                size = QSize(width, height);
                render(0); // Pre-render first frame
            }
        }
    }
    return animation != Q_NULLPTR;
}

void LottieIOPlugin::LottieIOHandler::finishRendering() {
    if (currentRender.valid()) {
        currentRender.get();
        prevImage = currentImage;
        if (!currentFrame && !firstImage.isNull()) {
            firstImage = currentImage;
        }
    } else {
        // Must be the first frame
        prevImage = currentImage;
    }
}

void LottieIOPlugin::LottieIOHandler::render(int frameIndex) {
    currentFrame = frameIndex % frameCount;
    if (!currentFrame && !firstImage.isNull()) {
        // The first frame only gets rendered once
        currentImage = firstImage;
    } else {
        const int width = (int)size.width();
        const int height = (int)size.height();
        currentImage = QImage(width, height, QImage::Format_ARGB32_Premultiplied);
        currentRender = animation->render(currentFrame,
            rlottie::Surface((uint32_t*)currentImage.bits(),
                width, height, currentImage.bytesPerLine()));
    }
}

bool LottieIOPlugin::LottieIOHandler::read(QImage* out) {
    if (load() && frameCount > 0) {
        // We must have the first frame, will wait if necessary
        if (currentFrame && currentRender.valid()) {
            std::future_status status = currentRender.wait_for(std::chrono::milliseconds(0));
            if (status != std::future_status::ready) {
                currentFrame = (currentFrame + 1) % frameCount;
                *out = prevImage;
                return true;
            }
        }
        finishRendering();
        *out = currentImage;
        render(currentFrame + 1);
        return true;
    }
    return false;
}

bool LottieIOPlugin::LottieIOHandler::canRead() const {
    return device();
}

QByteArray LottieIOPlugin::LottieIOHandler::name() const {
    return NAME;
}

QVariant LottieIOPlugin::LottieIOHandler::option(ImageOption option) const {
    switch (option) {
    case Size:
        ((LottieIOHandler*)this)->load(); // Cast off const
        return size;
    case Animation:
        return true;
    case ImageFormat:
        return QImage::Format_ARGB32_Premultiplied;
    default:
        break;
    }
    return QVariant();
}

bool LottieIOPlugin::LottieIOHandler::supportsOption(ImageOption option) const {
    switch(option) {
    case Size:
    case Animation:
    case ImageFormat:
        return true;
    default:
        break;
    }
    return false;
}

bool LottieIOPlugin::LottieIOHandler::jumpToNextImage() {
    if (frameCount) {
        finishRendering();
        render(currentFrame + 1);
        return true;
    }
    return false;
}

bool LottieIOPlugin::LottieIOHandler::jumpToImage(int imageNumber) {
    if (frameCount) {
        if (imageNumber != currentFrame) {
            finishRendering();
            render(imageNumber);
        }
        return true;
    }
    return false;
}

int LottieIOPlugin::LottieIOHandler::loopCount() const {
    return -1;
}

int LottieIOPlugin::LottieIOHandler::imageCount() const {
    return frameCount;
}

int LottieIOPlugin::LottieIOHandler::currentImageNumber() const {
    return currentFrame;
}

QRect LottieIOPlugin::LottieIOHandler::currentImageRect() const {
    return QRect(QPoint(), size);
}

int LottieIOPlugin::LottieIOHandler::nextImageDelay() const {
    return frameRate > 0 ? (int)(1000/frameRate) : 33;
}



QImageIOPlugin::Capabilities LottieIOPlugin::capabilities(QIODevice*, const QByteArray& format) const {
    return Capabilities((format == LottieIOHandler::NAME) ? CanRead : 0);
}

QImageIOHandler* LottieIOPlugin::create(QIODevice* device, const QByteArray& format) const {
    return new LottieIOHandler(device, format);
}
