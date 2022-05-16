#include <png.hpp>

class pixel_generator
  : public png::generator<png::gray_pixel_1, pixel_generator>
{
  public:
    pixel_generator(size_t width, size_t height);
    png::byte* get_next_row(size_t /*pos*/);

  private:
    typedef png::packed_pixel_row<png::gray_pixel_1> row;
    typedef png::row_traits<row> row_traits;
    row m_row;
};
