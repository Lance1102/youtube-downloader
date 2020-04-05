import QtQuick 2.14
import QtQuick.Controls 2.14

TextField {
    id: root

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40

        radius: Theme.Margins.tiny
        color: Theme.Colors.second
        border {
            width: Theme.Size.border
            color: Theme.Colors.base
        }
    }
}