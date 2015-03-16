//
//  MAPickerConstants.h
//

//---------------------------------------------------------------------------------

#define PICKER_W 320
#define PICKER_H 460

#define SZ(__s) UIViewAutoresizingFlexible ## __s
#define SZ_M(__s) UIViewAutoresizingFlexible ## __s ## Margin

//---------------------------------------------------------------------------------

#define ADD_LABEL(__var, __parent, __align, __font, __bold, __color, __auto, __x, __y, __w, __h) \
__var = [[UILabel alloc] initWithFrame: CGRectMake(__x, __y, __w, __h)]; \
__var.numberOfLines = 0; \
__var.textAlignment = __align; \
__var.autoresizingMask = __auto; \
__var.font = (__bold) ? [UIFont boldSystemFontOfSize: __font] : [UIFont systemFontOfSize: __font]; \
__var.textColor = __color; \
__var.backgroundColor = [UIColor clearColor]; \
[__parent addSubview: __var]; \
[__var release]
