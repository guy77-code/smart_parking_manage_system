/****************************************************************************
** Meta object code from reading C++ file 'userpage.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.8.3)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../userpage.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'userpage.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.8.3. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN8UserPageE_t {};
} // unnamed namespace


#ifdef QT_MOC_HAS_STRINGDATA
static constexpr auto qt_meta_stringdata_ZN8UserPageE = QtMocHelpers::stringData(
    "UserPage",
    "requestLogout",
    "",
    "onBtnPark",
    "onBtnLeave",
    "onBtnReserve",
    "onBtnViewHistory",
    "handleRefreshClicked",
    "onBtnLogoutClicked",
    "onUserStatusReply",
    "onEnterReply",
    "onExitReply",
    "onGenerateViolationReply"
);
#else  // !QT_MOC_HAS_STRINGDATA
#error "qtmochelpers.h not found or too old."
#endif // !QT_MOC_HAS_STRINGDATA

Q_CONSTINIT static const uint qt_meta_data_ZN8UserPageE[] = {

 // content:
      12,       // revision
       0,       // classname
       0,    0, // classinfo
      11,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   80,    2, 0x06,    1 /* Public */,

 // slots: name, argc, parameters, tag, flags, initial metatype offsets
       3,    0,   81,    2, 0x08,    2 /* Private */,
       4,    0,   82,    2, 0x08,    3 /* Private */,
       5,    0,   83,    2, 0x08,    4 /* Private */,
       6,    0,   84,    2, 0x08,    5 /* Private */,
       7,    0,   85,    2, 0x08,    6 /* Private */,
       8,    0,   86,    2, 0x08,    7 /* Private */,
       9,    0,   87,    2, 0x08,    8 /* Private */,
      10,    0,   88,    2, 0x08,    9 /* Private */,
      11,    0,   89,    2, 0x08,   10 /* Private */,
      12,    0,   90,    2, 0x08,   11 /* Private */,

 // signals: parameters
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,

       0        // eod
};

Q_CONSTINIT const QMetaObject UserPage::staticMetaObject = { {
    QMetaObject::SuperData::link<QWidget::staticMetaObject>(),
    qt_meta_stringdata_ZN8UserPageE.offsetsAndSizes,
    qt_meta_data_ZN8UserPageE,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_tag_ZN8UserPageE_t,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<UserPage, std::true_type>,
        // method 'requestLogout'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBtnPark'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBtnLeave'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBtnReserve'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBtnViewHistory'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'handleRefreshClicked'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onBtnLogoutClicked'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onUserStatusReply'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onEnterReply'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onExitReply'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'onGenerateViolationReply'
        QtPrivate::TypeAndForceComplete<void, std::false_type>
    >,
    nullptr
} };

void UserPage::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<UserPage *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->requestLogout(); break;
        case 1: _t->onBtnPark(); break;
        case 2: _t->onBtnLeave(); break;
        case 3: _t->onBtnReserve(); break;
        case 4: _t->onBtnViewHistory(); break;
        case 5: _t->handleRefreshClicked(); break;
        case 6: _t->onBtnLogoutClicked(); break;
        case 7: _t->onUserStatusReply(); break;
        case 8: _t->onEnterReply(); break;
        case 9: _t->onExitReply(); break;
        case 10: _t->onGenerateViolationReply(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _q_method_type = void (UserPage::*)();
            if (_q_method_type _q_method = &UserPage::requestLogout; *reinterpret_cast<_q_method_type *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
    }
}

const QMetaObject *UserPage::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *UserPage::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_ZN8UserPageE.stringdata0))
        return static_cast<void*>(this);
    return QWidget::qt_metacast(_clname);
}

int UserPage::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 11)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 11;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 11)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 11;
    }
    return _id;
}

// SIGNAL 0
void UserPage::requestLogout()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}
QT_WARNING_POP
