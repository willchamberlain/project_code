
using int_array1D_2 = int[2];
using int_array2D_2 = int_array1D_2[3];
using int_array3D_2 = int_array2D_2[4];


int main(int argc, char const *argv[])
{
    using int_array2D_1 = int[3][2];
    int_array2D_1 an_array_2D_1 = {{11,12},{21,22},{31,32}};

    using int_array3D_1 = int[4][3][2];
    int_array3D_1 an_array_3D_1 = {  
        {{111,112},{121,122},{131,132}} , 
        {{211,212},{221,222},{231,232}} , 
        {{311,312},{321,322},{331,332}} , 
        {{411,412},{421,422},{431,432}} 
     };

    //----------------------------------//

    int_array3D_2 an_array3D_2 = {  
        {{111,112},{121,122},{131,132}} , 
        {{211,212},{221,222},{231,232}} , 
        {{311,312},{321,322},{331,332}} , 
        {{411,412},{421,422},{431,432}} };

    return 0;
}


