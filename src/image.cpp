#include <png.hpp>

#include "image.hpp"

pixel_generator::pixel_generator(size_t width, size_t height)
  : png::generator<png::gray_pixel_1, pixel_generator>(width, height)
  , m_row(width)
{
    for (size_t i = 0; i < m_row.size(); ++i) {
        m_row[i] = i > m_row.size() / 2 ? 1 : 0;
    }
}

png::byte* pixel_generator::get_next_row(size_t /*pos*/)
{
    size_t i = std::rand() % m_row.size();
    size_t j = std::rand() % m_row.size();
    png::gray_pixel_1 t = m_row[i];
    m_row[i] = m_row[j];
    m_row[j] = t;
    return reinterpret_cast<png::byte*>(row_traits::get_data(m_row));
}
