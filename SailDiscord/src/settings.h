#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>

class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)
    Q_PROPERTY(bool emptySpace READ emptySpace WRITE setEmptySpace NOTIFY emptySpaceChanged)
    Q_PROPERTY(bool ignorePrivate READ ignorePrivate WRITE setIgnorePrivate NOTIFY ignorePrivateChanged)
    Q_PROPERTY(QString serverSize READ serverSize WRITE setServerSize NOTIFY serverSizeChanged)
    Q_PROPERTY(QString messageSize READ messageSize WRITE setMessageSize NOTIFY messageSizeChanged)
    Q_PROPERTY(bool messagesLessWidth READ messagesLessWidth WRITE setMessagesLessWidth NOTIFY messagesLessWidthChanged)
    Q_PROPERTY(QString sentBehaviour READ sentBehaviour WRITE setSentBehaviour NOTIFY sentBehaviourChanged)
    Q_PROPERTY(QString messagesPadding READ messagesPadding WRITE setMessagesPadding NOTIFY messagesPaddingChanged)
    Q_PROPERTY(bool alignMessagesText READ alignMessagesText WRITE setAlignMessagesText NOTIFY alignMessagesTextChanged)
    Q_PROPERTY(bool oneAuthor READ oneAuthor WRITE setOneAuthor NOTIFY oneAuthorChanged)
    Q_PROPERTY(bool oneAuthorPadding READ oneAuthorPadding WRITE setOneAuthorPadding NOTIFY oneAuthorPaddingChanged)

public:
    explicit Settings(QObject *parent = nullptr);

    QString token() const;
    Q_INVOKABLE void setToken(QString token);

    bool emptySpace() const;
    Q_INVOKABLE void setEmptySpace(bool emptySpace);

    bool ignorePrivate() const;
    Q_INVOKABLE void setIgnorePrivate(bool ignorePrivate);

    QString serverSize() const;
    Q_INVOKABLE void setServerSize(QString serverSize);

    QString messageSize() const;
    Q_INVOKABLE void setMessageSize(QString messageSize);

    bool messagesLessWidth() const;
    Q_INVOKABLE void setMessagesLessWidth(bool messagesLessWidth);

    QString sentBehaviour() const;
    Q_INVOKABLE void setSentBehaviour(QString sentBehaviour);

    QString messagesPadding() const;
    Q_INVOKABLE void setMessagesPadding(QString messagesPadding);

    bool alignMessagesText() const;
    Q_INVOKABLE void setAlignMessagesText(bool alignMessagesText);

    bool oneAuthor() const;
    Q_INVOKABLE void setOneAuthor(bool oneAuthor);

    bool oneAuthorPadding() const;
    Q_INVOKABLE void setOneAuthorPadding(bool oneAuthorPadding);

private:
    QSettings settings;

signals:
    void tokenChanged();
    void emptySpaceChanged();
    void ignorePrivateChanged();
    void serverSizeChanged();
    void messageSizeChanged();
    void messagesLessWidthChanged();
    void sentBehaviourChanged();
    void messagesPaddingChanged();
    void alignMessagesTextChanged();
    void oneAuthorChanged();
    void oneAuthorPaddingChanged();
};

#endif // SETTINGS_H
