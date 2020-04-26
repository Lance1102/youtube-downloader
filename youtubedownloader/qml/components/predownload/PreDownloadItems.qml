import QtQuick 2.14
import QtQuick.Layouts 1.12

import "../../items" as Items
import "../dynamic" as Dynamic

Item {
    id: root

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight + preDownloadItems.contentHeight // TODO: Is there another way?

    ColumnLayout {
        id: mainLayout

        anchors.fill: parent
        spacing: Theme.Margins.tiny

        Items.YDButton {
            id: downloadButton

            Layout.alignment: Qt.AlignHCenter

            text: qsTr("Download %1 items").arg(preDownloadItems.itemsReady)
            enabled: preDownloadItems.itemsReady && !preDownloadItems.itemsProcessing

            onClicked: downloadManager.download()

            state: "hidden"
            states: State {
                name: "hidden"
                when: (preDownloadItems.itemsReady === 0)
                PropertyChanges { target: downloadButton; opacity: Theme.Visible.off }
            }

            transitions: Transition {
                NumberAnimation { property: "opacity"; duration: Theme.Animation.quick }
            }
        }

        ListView {
            id: preDownloadItems

            property int itemsNotReady: Theme.Capacity.empty
            property int itemsProcessing: Theme.Capacity.empty
            readonly property int itemsReady: count - itemsNotReady - itemsProcessing

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            spacing: Theme.Margins.tiny
            model: predownloadModel

            delegate: PreDownloadItem {
                width: preDownloadItems.width

                property bool predownloadIsNotReady: (status === "exists")
                property bool predownloadIsProcessing: (status === "processing")
                onPredownloadIsNotReadyChanged: preDownloadItems.itemsNotReady += (predownloadIsNotReady) ? 1 : -1
                onPredownloadIsProcessingChanged: preDownloadItems.itemsProcessing += (predownloadIsProcessing) ? 1 : -1

                preDownloadStatus: status
                link: url
                linkTitle: title
                linkUploader: uploader
                linkUploaderLink: uploaderUrl
                linkDuration: duration

                downloadOptions: options

                thumbnailUrl: thumbnail
                selectedFormat: options.fileFormat
                destinationFile: "%1/%2.%3".arg(options.outputPath).arg(title).arg(options.fileFormat) // TOOD: Make a separate variable for this in Python

                onChangeFormat: {
                    options = { // TODO: Make it clean
                        "output_path": options.outputPath,
                        "file_format": format
                    }
                }

                onRemove: dialogManager.open_dialog("ConfirmDialog", {"text": qsTr("Are you sure you want to delete <b>%1</b> by <b>%2</b>?".arg(title).arg(uploader))}, function() {
                    predownloadModel.remove_predownload(index)
                })

                Component.onDestruction: {
                    if (predownloadIsNotReady) {
                        preDownloadItems.itemsNotReady -= 1
                    }
                }
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.Animation.quick }
    }
}
